require '../lib/stats_combiner'
require 'spec_credentials'
# spec_credentials.rb should include:
# KEY = 'chartbeat_api_key'
# HOST = 'your_chartbeat_host.com'

require 'spec'
require 'timecop'


describe "an unfiltered StatsCombiner cycle" do

  before :each do
    @flat_file = File.dirname(__FILE__) + '/test_flat_file.html'
    @ttl = 3600
    @s = StatsCombiner::Combiner.new({
      :ttl => @ttl, 
      :host=> HOST,
      :api_key=> KEY,
      :flat_file => @flat_file
    })
    @db_file = File.dirname(__FILE__) + '/stats_db.sqlite3'
  end
  
  it 'should do a first-time run, setting up the db' do
    @s.run()
    
    
    File.exist?(@db_file).should == true
    
    @db = Sequel.sqlite(@db_file)
    @db[:stories].all.should be_a(Array)
    @db[:create_time].all.should be_a(Array)
    
    #allow for a 2 second variation in timestamp
    @db[:create_time].select(:timestamp).first[:timestamp].to_i.should be_close((Time.now.to_i - 2),(Time.now.to_i + 2))
    
    @first_run_time = Time.now
  end
  
  it 'should do a second-time run, capturing data' do
    #set Time.now to 5 seconds from now
    t = Time.now
    Timecop.travel(t + 5)
    
    @s.run()

    File.exist?(@db_file).should == true

    @db = Sequel.sqlite(@db_file)   
    @db[:stories].all.length.should be >= 1
    first_story = @db[:stories].first
    first_story[:visitors].should be_a(Fixnum)
    first_story[:title].should be_a(String)
    first_story[:path].should be_a(String)
    
    #save first_story title & first_story visitors for use in the combiner test
    FIRST_STORY_TITLE = first_story[:title]
    FIRST_STORY_VISITORS = first_story[:visitors]
    Timecop.return
  end
  
  it 'should do a combining data capture' do
    @s.run()

    File.exist?(@db_file).should == true
    @db = Sequel.sqlite(@db_file)   
    
    # let's check to see that the titles array is unique
    # i.e., that dupes have been added together
    test_titles = []
    stories = @db[:stories].all
    stories.each do |story|
      test_titles << story[:title]
    end
    test_titles.uniq.size.should eql(stories.size)
    
    # now let's check that visit counts have been combined
    # for this, we'll *assume* that the first story in the array
    # (which has the higest visitor ct) will be combined.
    # We'll use @first_story_title we got in the second-time-run test
    @combined_story = @db[:stories].where(:title => FIRST_STORY_TITLE).first
    @combined_story[:title].should be_a(String)
    @combined_story[:visitors].should > FIRST_STORY_VISITORS
  end
  
  it 'should report data and dump db' do
    # set Time.now to 5 seconds past ttl
    t = Time.now
    Timecop.travel(t + @ttl + 5)
  
    @s.run()
    
    File.exist?(@flat_file).should == true
    File.exist?(@db_file).should == false
    
    Timecop.return
  end
  
  
  after :all do
    FileUtils.rm_rf(@db_file)
    FileUtils.rm_rf(@flat_file)
  end
  
end

describe "basic Filterer filtering" do
   
  before :each do
    @f = StatsCombiner::Filterer.new
  end
  
  it 'should add a rule to the filters array' do
    @f.add :prefix => 'tpmdc', :title_regex => /\| TPMDC/, :modify_title => true
    
    @f.filters.size.should eql(1)
  end
  
  # various filter cases
  it 'should set a prefix according to a title_regex' do
    @f.add :prefix => 'tpmdc', :title_regex => /\| TPMDC/
    datum = {:visitors=>366, :created_at=>nil, :path=>"/2010/05/with-specter-suffering-white-house-and-gop-looking-at-surging-sestak.php", :id=>3, :title=>"With Specter Suffering, White House And GOP Looking At Surging Sestak | TPMDC"}

    result = StatsCombiner::Filterer.apply_filters!(@f.filters,datum)
    result[:prefix].should eql("tpmdc")
  end

  it 'should modify a title based on a title_regex' do
    @f.add :prefix => 'tpmdc', :title_regex => /\| TPMDC/, :modify_title => true
    
    datum = {:visitors=>366, :created_at=>nil, :path=>"/2010/05/with-specter-suffering-white-house-and-gop-looking-at-surging-sestak.php", :id=>3, :title=>"With Specter Suffering, White House And GOP Looking At Surging Sestak | TPMDC"}

    result = StatsCombiner::Filterer.apply_filters!(@f.filters,datum)
    result[:title].should eql("With Specter Suffering, White House And GOP Looking At Surging Sestak")
  end
  
  it 'should set a suffix where it matches a path_regex and modify a path where indicated' do
    @f.add :path_regex => /(\?ref=.*$|\&ref=.*$|)/, :suffix => '', :modify_path => true
  
    datum = {:visitors=>366, :created_at=>nil, :path=>"/2010/05/with-specter-suffering-white-house-and-gop-looking-at-surging-sestak.php?ref=fpa", :id=>3, :title=>"With Specter Suffering, White House And GOP Looking At Surging Sestak | TPMDC"}
    
    result = StatsCombiner::Filterer.apply_filters!(@f.filters,datum)
    result[:path].should eql("/2010/05/with-specter-suffering-white-house-and-gop-looking-at-surging-sestak.php")
  end
  
  it 'should set a suffix where it matches a path_regex and append a path where indicated' do
    @f.add :path_regex => /(\?id=.*$|\?page=.*$|\?img=.*$)/, :suffix => '&ref=mp', :append_to_path => true  
    datum = {:visitors=>366, :created_at=>nil, :path=>"/2010/05/with-specter-suffering-white-house-and-gop-looking-at-surging-sestak.php?id=1", :id=>3, :title=>"With Specter Suffering, White House And GOP Looking At Surging Sestak | TPMDC"}
    
    result = StatsCombiner::Filterer.apply_filters!(@f.filters,datum)
    result[:path].should eql("/2010/05/with-specter-suffering-white-house-and-gop-looking-at-surging-sestak.php?id=1&ref=mp")
  end
  
  it 'should nil out data where exclude is true' do
    #first, two examples of a matching regex
    
    @f.add :path_regex => /(\/$|\/index.php$)/, :exclude => true
    
    datum = {:visitors=>3090, :created_at=>nil, :path=>"/", :id=>1, :title=>"Talking Points Memo | Breaking News and Analysis"}
    
    result = StatsCombiner::Filterer.apply_filters!(@f.filters,datum)
    result[:title].should be_nil
    result[:path].should be_nil
    
    @f.filters.clear

    @f.add :path_regex => /talk\/blogs/, :exclude => true
    
    datum = {:visitors=>6, :created_at=>nil, :path=>"/talk/blogs/a/m/americandad/2010/03/an-open-letter-to-conservative.php/", :id=>31, :title=>"An open letter to conservatives | AmericanDad's Blog"}
    
    result = StatsCombiner::Filterer.apply_filters!(@f.filters,datum)
    result[:title].should be_nil
    result[:path].should be_nil
   
    @f.filters.clear
    
    #now, let's look for invalid data. run a regex against a nonmatch
    @f.add :path_regex => /(\/$|\/index.php$)/, :exclude => true
    
    datum = {:visitors=>6, :created_at=>nil, :path=>"/talk/blogs/a/m/americandad/2010/03/an-open-letter-to-conservative.php", :id=>31, :title=>"An open letter to conservatives | AmericanDad's Blog"}    
    
    result = StatsCombiner::Filterer.apply_filters!(@f.filters,datum)
    result[:title].should_not be_nil
    result[:path].should_not be_nil
  end
  
end

describe "filtered StatsCombining" do

end