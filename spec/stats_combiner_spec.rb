require '../lib/stats_combiner'
require 'spec'
require 'timecop'

describe StatsCombiner do

  before :each do
    @flat_file = File.dirname(__FILE__) + '/test_flat_file.html'
    @ttl = 3600
    @s = StatsCombiner::Combiner.new({
      :ttl => @ttl, 
      :host=>'talkingpointsmemo.com',
      :api_key=> 'KEY',
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
    
    Timecop.return
  end
  
  it 'should do a combining data capture'
  #this will be tough
  
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