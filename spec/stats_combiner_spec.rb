require '../lib/stats_combiner'
require 'spec_credentials'
# spec_credentials.rb should include:
# KEY = 'chartbeat_api_key'
# HOST = 'your_chartbeat_host.com'

require 'spec'
require 'timecop'
require 'hpricot'


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

  it 'should modify a title based on a title_regex and a modify_title boolean' do
    @f.add :prefix => 'tpmdc', :title_regex => /\| TPMDC/, :modify_title => true
    
    datum = {:visitors=>366, :created_at=>nil, :path=>"/2010/05/with-specter-suffering-white-house-and-gop-looking-at-surging-sestak.php", :id=>3, :title=>"With Specter Suffering, White House And GOP Looking At Surging Sestak | TPMDC"}

    result = StatsCombiner::Filterer.apply_filters!(@f.filters,datum)
    result[:title].should eql("With Specter Suffering, White House And GOP Looking At Surging Sestak")
  end

  it 'should modify a title based on a title_regex and a modify_title regex' do
    @f.add :prefix => 'tpmdc', :title_regex => /(\| TPMDC)$/, :modify_title => '\1 Central'
    
    datum = {:visitors=>366, :created_at=>nil, :path=>"/2010/05/with-specter-suffering-white-house-and-gop-looking-at-surging-sestak.php", :id=>3, :title=>"With Specter Suffering, White House And GOP Looking At Surging Sestak | TPMDC"}

    result = StatsCombiner::Filterer.apply_filters!(@f.filters,datum)
    result[:title].should eql("With Specter Suffering, White House And GOP Looking At Surging Sestak | TPMDC Central")
  end
  
  it 'should set a suffix where it matches a path_regex and modify a path according to a suffix regex' do
    @f.add :path_regex => /(\?ref=.*)$/, :suffix => '\1&foo=bar', :modify_path => true
  
    datum = {:visitors=>366, :created_at=>nil, :path=>"/2010/05/with-specter-suffering-white-house-and-gop-looking-at-surging-sestak.php?ref=fpa", :id=>3, :title=>"With Specter Suffering, White House And GOP Looking At Surging Sestak | TPMDC"}
    
    result = StatsCombiner::Filterer.apply_filters!(@f.filters,datum)
    result[:path].should eql("/2010/05/with-specter-suffering-white-house-and-gop-looking-at-surging-sestak.php?ref=fpa&foo=bar")
    
    @f.filters.clear
    
    #another example to kill unwanted query strings
    @f.add :path_regex => /((\?|&)ref=.*)/, :suffix => '', :modify_path => true
 
     datum = {:visitors=>366, :created_at=>nil, :path=>"/2010/05/with-specter-suffering-white-house-and-gop-looking-at-surging-sestak.php?id=keepme&ref=killme", :id=>3, :title=>"With Specter Suffering, White House And GOP Looking At Surging Sestak | TPMDC"}
    
    result = StatsCombiner::Filterer.apply_filters!(@f.filters,datum)
    result[:path].should eql("/2010/05/with-specter-suffering-white-house-and-gop-looking-at-surging-sestak.php?id=keepme")
  end

  
  it 'should nil out data where exclude is true and path or title regexes are matched' do
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
    
    @f.filters.clear
    
    #try a title match
    @f.add :title_regex => /(Breaking News and Analysis)/, :exclude => true
    
    datum = {:visitors=>3090, :created_at=>nil, :path=>"/", :id=>1, :title=>"Talking Points Memo | Breaking News and Analysis"}
    
    result = StatsCombiner::Filterer.apply_filters!(@f.filters,datum)
    result[:title].should be_nil
    result[:path].should be_nil    
    
  end
  
end

# best way to do this (without prying open the Class) might be 
# to define a set of filters, timetravel our way to the flat file stage, 
# open it and parse the HTML with hpricot for rules.
# Caveats - filters will be pretty specific 
# to whatever account is running this suite. So, proceed with caution.
describe "filtered StatsCombining" do

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

  it 'should run its way through the cycle and publish out a top ten list according to filter rules' do
  
    # first, let's set the filters we want to apply
    e = StatsCombiner::Filterer.new
    e.add :prefix => 'tpmdc', :title_regex => /\| TPMDC/, :modify_title => true
    e.add :prefix => 'tpmmuckraker', :title_regex => /\| TPMMuckraker/, :modify_title => true
    e.add :prefix => 'tpmtv', :title_regex => /\| TPMTV/, :modify_title => true
    e.add :prefix => 'tpmcafe', :title_regex => /\| TPMCafe/, :modify_title => true
    e.add :prefix => 'tpmlivewire', :title_regex => /\| TPM LiveWire/, :modify_title => true
    e.add :prefix => 'polltracker', :title_regex => /\| TPM PollTracker/, :modify_title => true
    e.add :prefix => 'www', :title_regex => /\|.*$/, :modify_title => true  
    e.add :path_regex => /(\/$|\/index.php$)/, :exclude => true  
    
    # now, let's go through the rigamarole to get this thing pubbed.
    # run to setup db
    @s.run :filters => e.filters
    # run again to start publishing
    @s.run :filters => e.filters
    # timetravel to pub time and do it.
    # * set Time.now to 5 seconds past ttl
    t = Time.now
    Timecop.travel(t + @ttl + 5)
    
    # add filters
    @s.run :filters => e.filters
    
    # sanity check
    File.exist?(@flat_file).should == true
    
    # open the file we just made
    list = File.open(@flat_file).read
    list = Hpricot(list)
    
    # collect urls and titles
    urls = []
    titles = []
    list.search("a").each do |a|
      urls << a.attributes['href']
      titles << a.inner_html
    end  
    
    # let's make sure we have 10 stories
    urls.size.should eql(10)
    
    # pull prefixes from rules array
    prefixes = e.filters.collect { |filter| filter[:rule][:prefix] }
    
    # test prefixes against subdomains
    urls.each do |url|
        subdomain = URI.parse(url).host.split('.')[0]
        prefixes.include?(subdomain).should == true
    end
    
    Timecop.return
  end

  after :all do
    FileUtils.rm_rf(@db_file)
    FileUtils.rm_rf(@flat_file)
  end

end