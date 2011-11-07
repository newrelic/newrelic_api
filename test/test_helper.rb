# Normally you hardwire the test environment in the test helper.  But 
# if you explicitly set it to development we'll pick that up instead.
ENV["RAILS_ENV"] ||= "test"

require 'rubygems'

# Set up gems listed in the Gemfile.
gemfile = File.expand_path('../../Gemfile', __FILE__)
begin
  ENV['BUNDLE_GEMFILE'] = gemfile
  require 'bundler'
  Bundler.setup
rescue Bundler::GemNotFound => e
  STDERR.puts e.message
  STDERR.puts "Try running `bundle install`."
  exit!
end if File.exist?(gemfile)
#require File.expand_path('../../config/environment', __FILE__)
require "active_resource/railtie"
require "rails/test_unit/railtie"
require 'rails/test_help'
require 'shoulda'
require 'logging'

$LOAD_PATH << File.expand_path("../../lib", __FILE__)
Dir.mkdir "log" unless File.directory? "log"
ActiveResource::Base.logger = Logger.new(File.expand_path('../../log/test.log', __FILE__))
ActiveResource::Base.logger.level = Logger::DEBUG
class ActiveSupport::TestCase
  # Add more helper methods to be used by all tests here...
end
