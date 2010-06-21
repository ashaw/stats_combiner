require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "stats_combiner"
    gem.summary = %Q{StatsCombiner creates most-viewed story widgets from the Chartbeat API}
    gem.description = %Q{A tool to create most-viewed story widgets from the Chartbeat API.}
    gem.email = "almshaw@gmail.com"
    gem.homepage = "http://github.com/tpm/stats_combiner"
    gem.authors = ["Al Shaw"]
    gem.add_dependency 'chartbeat'
    gem.add_dependency 'sequel'
    gem.add_development_dependency "rspec"
    gem.add_development_dependency "fakeweb"
    gem.add_development_dependency "timecop"
    gem.add_development_dependency "hpricot"

    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec
