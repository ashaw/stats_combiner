module StatsCombiner

  class Filterer 
    
    attr_accessor :filters
    
    # Initialize a filters object:
    #  e = StatsCombiner::Filterer.new
    #
    def initialize()
      @filters ||= []
    end 
    
    
    # Add a filter that StatsCombiner can use to manipulate paths and titles it
    # gets from Chartbeat.
    # 
    # options:                  Pattern: <tt>http://{prefix}.{host}/{path}{suffix}</tt>
    #
    #  prefix => nil            Filter on a prefix
    #  suffix => nil            Filter on a suffix
    #  title_regex => nil       Filter on a title pattern
    #  path_regex=> nil         Filter on a path pattern
    #
    #  modify_title => true     Modify the title inline via the regex
    #  modify_path => true      Modify the path inline via the regex
    #  append_to_path => true   Append suffix to path rather than modifying it
    #  exclude => true          Exclude this pattern from the top ten list
    # 
    # Some examples from TPM:
    #  e.add :prefix => 'tpmdc', :title_regex => /\| TPMDC/, :modify_title => true
    #  e.add :prefix => 'tpmmuckraker', :title_regex => /\| TPMMuckraker/, :modify_title => true
    #  e.add :prefix => 'tpmtv', :title_regex => /\| TPMTV/, :modify_title => true
    #  e.add :prefix => 'tpmcafe', :title_regex => /\| TPMCafe/, :modify_title => true
    #  e.add :prefix => 'tpmlivewire', :title_regex => /\| TPM LiveWire/, :modify_title => true
    #  e.add :prefix => 'tpmpolltracker', :title_regex => /\| TPM PollTracker/, :modify_title => true
    #
    #  e.add :prefix => 'www', :title_regex => /\|.*$/, :modify_title => true
    #  e.add :path_regex => /(\?ref=.*$|\&ref=.*$|)/, :suffix => '', :modify_path => true
    #  e.add :path_regex => /(\?id=.*$|\?page=.*$|\?img=.*$)/, :suffix => '&ref=mp', :append_to_path => true
    #
    # Excludes are good for filtering out index pages, etc.
    #  e.add :path_regex => /(\/$|\/index.php$)/, :exclude => true
    #  
    def add(options={})   
      { :prefix => nil,
        :suffix => nil,
        :title_regex => nil,
        :path_regex => nil,
        :modify_title => false, 
        :exclude => false,
      }.merge!(options)
      
      filter = {}
      filter[:rule] = {}.merge!(options)
            
      @filters << filter
    end
  
    # sanity check
    def list_filters
      @filters.each do |filter|
        p filter[:rule]
      end
    end
    
    # a datum comes in from chartbeat data, and is manipulated
    # with the apply_filters method, and sent back to Combiner to write out
    #
    # Grab filters with <tt>e.filters</tt>
    def self.apply_filters!(filters,datum={})      
      { :title => nil,
        :path => nil,
        :prefix => nil
      }.merge!(datum)
      
      @datum = datum
      
      filters.each do |filter|
				 @filter = filter[:rule] 
				 
				 self.title_to_prefix
				 self.suffix_to_path
				 self.modify_title
				 self.apply_exclude
				 
				 @filter.clear
      end
    
     datum
     
    end
	
	protected
	
		#set prefixes where they match title regexes
    def self.title_to_prefix
			if (@filter[:prefix] && @filter[:title_regex]) && @datum[:title].match(@filter[:title_regex])
					@datum[:prefix] = @filter[:prefix]
			end  
  	end

		#set suffixes where they match path regexes
		# if :modify_path => true, replace on regex
		# if :append_path => true, append to end of path
  	def self.suffix_to_path
			if (@filter[:suffix] && @filter[:path_regex]) && @datum[:path].match(@filter[:path_regex])
				if @filter[:modify_path]
					@datum[:path].gsub!(@filter[:path_regex],@filter[:suffix])
				elsif @filter[:append_to_path]
					@datum[:path] = @datum[:path] + @filter[:suffix]       
				end
			end  	
  	end
  	
  	def self.modify_title
			if @filter[:modify_title]
				@datum[:title].gsub!(@filter[:title_regex], '')
				@datum[:title].strip!
			end  	
  	end
  	
  	def self.apply_exclude
			if @filter[:exclude] && @datum[:path].match(@filter[:path_regex])        
					# nil out @datum.
					# StatsCombiner::Combiner will sweep away the nils later
					@datum[:title] = @datum[:path] = @datum[:prefix] = nil
			end  	
  	end
  
  end

end

