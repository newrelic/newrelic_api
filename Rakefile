require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'
require 'jeweler'
require 'rdiscount'

require 'ci/reporter/rake/test_unit'
TITLE = %Q{Documentation and helper code for the New Relic API}
RDOC_FILES=['README*', 'CHANGELOG', 'sample*']
Jeweler::Tasks.new do |gem|
  gem.name = "newrelic_api"
  gem.homepage = "http://www.github.com/newrelic/newrelic_api"
  gem.license = "MIT"
  gem.summary = TITLE
  gem.description = %Q{Use this gem to access New Relic application information via a REST api}
  gem.email = "support@newrelic.com"
  gem.authors = ["New Relic"]
  gem.extra_rdoc_files = FileList[*RDOC_FILES]
  gem.rdoc_options <<
      "--line-numbers" <<
      "--title" << TITLE <<
      "-m" << "README.rdoc"
end
#Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

require 'rcov/rcovtask'
Rcov::RcovTask.new do |test|
  test.libs << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = TITLE
  rdoc.rdoc_files.include(*RDOC_FILES)
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.main = "README.rdoc"
end
