require File.dirname(__FILE__) + './lib/stats_combiner'

s = StatsCombiner::Combiner.new({
	:ttl => 3600, 
	:host => 'talkingpointsmemo.com',
	:api_key => 'YOURKEY',
	:flat_file => '/Applications/MAMP/htdocs/rb_top_ten.html'
})

e = StatsCombiner::Filterer.new
e.add :prefix => 'tpmdc', :title_regex => /\| TPMDC/, :modify_title => true
e.add :prefix => 'tpmmuckraker', :title_regex => /\| TPMMuckraker/, :modify_title => true
e.add :prefix => 'tpmtv', :title_regex => /\| TPMTV/, :modify_title => true
e.add :prefix => 'tpmcafe', :title_regex => /\| TPMCafe/, :modify_title => true
e.add :prefix => 'tpmlivewire', :title_regex => /\| TPM LiveWire/, :modify_title => true
e.add :prefix => 'tpmpolltracker', :title_regex => /\| TPM PollTracker/, :modify_title => true
e.add :prefix => 'www', :title_regex => /\|.*$/, :modify_title => true

#put excluders last
e.add :path_regex => /(\/$|\/index.php$)/, :exclude => true

s.run({
	:filters => e.filters,
	:verbose => true
})