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
API_VERSION = File.read('CHANGELOG')[/^.*$/]
TITLE = %Q{Deprecated: Helper code for the New Relic API}
RDOC_FILES=Dir['README*', 'CHANGELOG', 'sample*']
Jeweler::Tasks.new do |gem|
  gem.version = API_VERSION
  gem.name = "newrelic_api"
  gem.homepage = "http://www.github.com/newrelic/newrelic_api"
  gem.license = "MIT"
  gem.summary = TITLE
  gem.description = %Q{See https://docs.newrelic.com/docs/apm/apis for details on our current API}
  gem.email = "support@newrelic.com"
  gem.authors = ["New Relic"]
  gem.extra_rdoc_files = FileList[*RDOC_FILES]
  gem.rdoc_options <<
      "--line-numbers" <<
      "--title" << TITLE <<
      "-m" << "README.rdoc"
end

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
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = TITLE
  # I don't know why, but the next line has no effect
  rdoc.rdoc_files.include(*RDOC_FILES)
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.main = "README.rdoc"
end
