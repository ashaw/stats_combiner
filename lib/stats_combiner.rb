require 'open-uri'
require 'fileutils'
require 'rubygems'
require 'crack/json'
require 'sequel'

class StatsCombiner
  
  # Usage:
  #
  # s = StatsCombiner.new({
  #       :api_key => 'your_key',
  #       :host => 'talkingpointsmemo.com',
  #       :ttl => 3600,
  #       :story_count => 10,
  #       :flat_file => '/var/www/html/topten.html'
  #     })  
  def initialize(opts = {})
    @init_options = opts
    @db_file = "stats_db.sqlite3"
  end

  # check where we are in the cycle
  # and run the necessary functions
  # call this after initializing StatsCombiner
  # 
  # Usage:
  #  s.run({
  #   :verbose => true
  #  })
  def run(opts = {})
    now = Time.now
    if File::exists?(@db_file)
      @db = Sequel.sqlite(@db_file)
      @table_create_time = self.table_create_time
      @table_destroy_time = @table_create_time + @init_options[:ttl]
      @ttl = @table_destroy_time.to_i - Time.now.to_i
      
      if now.to_i < @table_destroy_time.to_i 
       self.combine
       if opts[:verbose]
        puts "Combining. DB has #{@ttl} seconds to live"
       end
      else
       self.report_and_cleanup
       if opts[:verbose]
        puts "ttl expired. reporting and cleaning up"
        end
      end
    else
      self.setup
      if opts[:verbose]
        puts "No DB detected. I set one up"
      end
    end
  end

  def set_rewrite_rule
  
  end 

protected

  # Set up the database.
  # This is done once every timeout cycle
  def setup
    @db = Sequel.sqlite(@db_file)
    @db.create_table :stories do
      primary_key    :id,       :type => Integer
      String         :title,    :text => true
      String         :path,     :text => true
      Fixnum         :visitors
      DateTime       :created_at
    end
    
    @db.create_table :create_time do
      primary_key    :id,       :type => Integer
      DateTime       :timestamp
    end
    
    now = Time.now
    time_table = @db[:create_time]
    time_table.insert(:timestamp => now)
  end
  
  def table_create_time
    @db[:create_time].select(:timestamp).first[:timestamp]
  end
  
  def destroy
    FileUtils.rm_rf(@db_file)
  end
  
  # grab the data, and parse it into something we can use
  # and combine it
  def combine
    host = @init_options[:host]
    api_key = @init_options[:api_key]
    @url = "http://api.chartbeat.com/toppages/?host=#{host}&limit=50&apikey=#{api_key}"
    
    @data = open(@url).read
    @data = Crack::JSON.parse(@data)
  
    @data.each do |datum|
      visitors = datum['visitors']
      path = datum['path']
      title = datum['i']
      
      # if the story is already in the db, combine visitor count
      # otherwise insert a new row
      existing_story = @db[:stories].where(:title => title).first || ''
      
      if not existing_story.empty?
        existing_visitors = existing_story[:visitors]
        @db[:stories].where(:title => title).update :visitors => existing_visitors + visitors
      else
        @db[:stories].insert({
          :title => title,
          :visitors => visitors,
          :path => path
         })
      end
      
    end
  end
  
  # Pull data out of the db, write the flat file and dump the db.
  # This is done once every timeout cycle.
  def report_and_cleanup
   top_ten = @db[:stories].all[0..9]
   now = Time.now
   flat_file = @init_options[:flat_file]
  
   html = '<ul>'

   top_ten.each do |story|
     title = story[:title]
     path = story[:path]
     visitors = story[:visitors]
    
     html << "<li><a href=\"#{path}\">#{title}</a></li> <!-- #{visitors} -->"
   end
    
   html << '</ul>'
   html << "<!-- This report was generated at #{now} -->"
  
   flat_file = File.new(flat_file, "w+")
   flat_file.write(html)
   flat_file.close
   
   self.destroy
  end

end