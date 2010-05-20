require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "stats_combiner"
    gem.summary = %Q{StatsCombiner creates most viewed widgets from the Chartbeat API}
    gem.description = %Q{A tool to create most viewed widgets from the Chartbeat API.}
    gem.email = "almshaw@gmail.com"
    gem.homepage = "http://github.com/ashaw/stats_combiner"
    gem.authors = ["Al Shaw"]
    gem.add_dependency 'crack'
    gem.add_dependency 'sequel'
    gem.add_development_dependency "rspec"
    gem.add_development_dependency "timecop"
    gem.add_development_dependency "hpricot"

    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/  20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end