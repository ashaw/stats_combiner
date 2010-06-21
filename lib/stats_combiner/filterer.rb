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
    # Options:                            Pattern: <tt>http://{prefix}.{host}/{path}{suffix}</tt>
    #
    # search by..
    #  title_regex => nil                 Filter on a title pattern
    #  path_regex=> nil                   Filter on a path pattern
    #
    # ..to add a:
    #  suffix => nil                      a path modification
    #  prefix => nil                      a subdomain
    #  modify_title => bool or regexp     Modify the title inline
    #
    # Or, to ignore the entry:
    #  exclude => true                    Exclude this pattern from the top ten list
    # 
    # Some examples from TPM:
    #  e.add :prefix => 'tpmdc', :title_regex => /\| TPMDC/, :modify_title => true
    #  e.add :path_regex => /(\?ref=.*$|\&ref=.*$|)/, :suffix => '', :modify_path => true
    #  e.add :path_regex => /(\?(page|img)=(.*)($|&))/, :suffix => '?\2=1'
    #  e.add :path_regex => /(\/$|\/index.php$)/, :exclude => true
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
      
        filters.each do |filter|
          
          #skip filters if datum has already been nil'd
          if not (datum[:title].nil? || datum[:path].nil?)
        
            # set prefixes where they match title regexes
            # /\| TPMDC/ => http://tpmdc
            if (filter[:rule][:prefix] && filter[:rule][:title_regex]) && datum[:title].match(filter[:rule][:title_regex])
                datum[:prefix] = filter[:rule][:prefix]
            end
            
            # modify path => '?q=new_suffix'
            # append to path with regex replacement variables => '\1&new_suffix'
            if (filter[:rule][:suffix] && filter[:rule][:path_regex]) && datum[:path].match(filter[:rule][:path_regex])
                  datum[:path].gsub!(filter[:rule][:path_regex],filter[:rule][:suffix])
            end
            
            # apply title mods
            # modify_title => true /==> 
            # modify_title => "DC Central"
            # title_regex => /| TPMDC/,  modify_title => '\1 Central' ==> TPMDC Central
            if filter[:rule][:modify_title]
              filter[:rule][:modify_title] = '' unless filter[:rule][:modify_title].is_a?(String)
              datum[:title].gsub!(filter[:rule][:title_regex], filter[:rule][:modify_title])
              datum[:title].strip!
            end
            
            # apply excludes. 
            # this should take out the whole record if it matches a path or title regex
            if filter[:rule][:exclude] && ((filter[:rule][:path_regex].is_a?(Regexp) && datum[:path].match(filter[:rule][:path_regex])) || (filter[:rule][:title_regex].is_a?(Regexp) && datum[:title].match(filter[:rule][:title_regex])))        
                # nil out datum.
                # StatsCombiner::Combiner will sweep away the nils later
                datum[:title] = datum[:path] = datum[:prefix] = nil
            end
        
          end
      
        end
      
      datum
     
    end
  
  
  end

end

