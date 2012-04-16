require 'active_resource_associations'

# = New Relic REST API
#
# This is a helper module for working with the New Relic API's XML interface.  Requires Rails 2.0 or later to be loaded.
#
# Can also be used as a script using script/runner.
#
# In this version of the api, authentication is handled using your account API key, available in your Account settings
# in http://rpm.newrelic.com.  
# Log in, click Account at the top of the page and check the "Make my account data accessible" checkbox.  An
# API key will appear.
#
# Refer to the README file for details and examples on the REST API.
#
# == Examples
#
#   # Fetching the list of applications for an account
#   NewRelicApi::Account.find(:first).applications
#
#   # Fetching the health values for all account applications
#   NewRelicApi::Account.application_health
#
#   # Fetching the health values for an application
#   NewRelicApi::Account.find(:first).applications.first.threshold_values
#
#   # Finding an application by name
#   NewRelicApi::Account.find(:first).applications(:params => {:conditions => {:name => 'My App'}})
#

module NewRelicApi

  class << self
    attr_accessor :api_key, :ssl, :host, :port, :proxy

    # Resets the base path of all resources.  This should be called when overridding the newrelic.yml settings
    # using the ssl, host or port accessors.
    def reset!
      @classes.each {|klass| klass.reset!} if @classes
      NewRelicApi::Account.site_url
    end


    def track_resource(klass) #:nodoc:
      (@classes ||= []) << klass
    end
  end

  class BaseResource < ActiveResource::Base #:nodoc:
    include ActiveResourceAssociations

    class << self

      def inherited(klass) #:nodoc:
        NewRelicApi.track_resource(klass)
      end

      def headers
        raise "api_key required" unless NewRelicApi.api_key
        {'x-api-key' => NewRelicApi.api_key}
      end

      def site_url
        host = NewRelicApi.host || 'rpm.newrelic.com'
        port = NewRelicApi.port || 80
        "#{port == 443 ? 'https' : 'http'}://#{host}:#{port}"
      end

      def reset!
        self.site = self.site_url
      end

      def proxy
        NewRelicApi.proxy
      end
    end
    self.format = ActiveResource::Formats::XmlFormat
    self.site = self.site_url
    self.proxy = self.proxy
  end
  ACCOUNT_RESOURCE_PATH = '/accounts/:account_id/' #:nodoc:
  ACCOUNT_AGENT_RESOURCE_PATH = ACCOUNT_RESOURCE_PATH + 'agents/:agent_id/' #:nodoc:
  ACCOUNT_APPLICATION_RESOURCE_PATH = ACCOUNT_RESOURCE_PATH + 'applications/:application_id/' #:nodoc:

  module AccountResource #:nodoc:
    def account_id
      prefix_options[:account_id]
    end
    def account_query_params(extra_params = {})
      {:account_id => account_id}.merge(extra_params)
    end

    def query_params#:nodoc:
      account_query_params
    end
  end

  module AgentResource #:nodoc:
    include ActiveResourceAssociations
  end

  # An application has many:
  # +agents+:: the agent instances associated with this app
  # +threshold_values+:: the health indicators for this application.
  class Application < BaseResource
    include AccountResource
    include AgentResource

    has_many :agents, :threshold_values

    self.prefix = ACCOUNT_RESOURCE_PATH

    def query_params#:nodoc:
      account_query_params(:application_id => id)
    end

    class Agent < BaseResource
      include AccountResource
      include AgentResource

      self.prefix = ACCOUNT_APPLICATION_RESOURCE_PATH

      def query_params#:nodoc:
        super.merge(:application_id => cluster_agent_id)
      end
    end

  end

  # A threshold value represents a single health indicator for an application such as CPU, memory or response time.
  #
  # ==Fields
  # +name+:: The name of the threshold setting associated with this threshold value.
  # +begin_time+:: Time value indicating start of evaluation period, as a string.
  # +threshold_value+:: A value of 0, 1, 2 or 3 representing gray (not reporting), green, yellow and red
  # +metric_value+:: The metric value associated with this threshold
  class ThresholdValue < BaseResource
    self.prefix = ACCOUNT_APPLICATION_RESOURCE_PATH

    #   attr_reader :name, :begin_time, :metric_value, :threshold_value

    # Return theshold_value as 0, 1, 2, or 3 representing grey (not reporting)
    # green, yellow, and red, respectively.
    def threshold_value
      super.to_i
    end

    # Return the actual value of the threshold as a Float
    def metric_value
      super.to_f
    end
    # Returns the color value for this threshold (Gray, Green, Yellow or Red).
    def color_value
      case threshold_value
        when 3 then 'Red'
        when 2 then 'Yellow'
        when 1 then 'Green'
      else 'Gray'
      end
    end

    def to_s #:nodoc:
      "#{name}: #{color_value} (#{formatted_metric_value})"
    end
  end

  # An account contains your basic account information.
  #
  # Accounts have many
  # +applications+:: the applications contained within the account
  #
  # Find Accounts
  #
  #   NewRelicApi::Account.find(:first) # find account associated with the api key
  #   NewRelicApi::Account.find(44)     # find individual account by ID
  #
  class Account < BaseResource
    has_many :applications
    has_many :account_views

    def query_params #:nodoc:
      {:account_id => id}
    end

    # Returns an account including all of its applications and the threshold values for each application.
    def self.application_health(type = :first)
      find(type, :params => {:include => :application_health})
    end

    class AccountView < BaseResource
      self.prefix = ACCOUNT_RESOURCE_PATH

      def query_params(extra_params = {}) #:nodoc:
        {:account_id => account_id}.merge(extra_params)
      end

      def user
        @attributes['user']
      end
    end

    class AccountUsage < BaseResource
    end
  end

  # This model is used to mark production deployments in RPM
  # Only create is supported.
  # == Options
  # 
  # Exactly one of the following is required:
  # * <tt>app_name</tt>: The value of app_name in the newrelic.yml file used by the application.  This may be different than the label that appears in the RPM UI.  You can find the app_name value in RPM by looking at the label settings for your application.
  # * <tt>application_id</tt>: The application id, found in the URL when viewing the application in RPM.
  #
  # Following are optional parameters:
  # * <tt>description</tt>: Text annotation for the deployment &mdash; notes for you
  # * <tt>changelog</tt>: A list of changes for this deployment
  # * <tt>user</tt>: The name of the user/process that triggered this deployment
  #
  # ==Example
  #
  #   NewRelicApi::Deployment.create :application_id => 11142007, :description => "Update production", :user => "Big Mike"
  #
  #   NewRelicApi::Deployment.create :app_name => "My Application", :description => "Update production", :user => "Big Mike"
  #
  class Deployment < BaseResource
  end

  class Subscription < BaseResource
    def query_params(extra_params = {}) #:nodoc:
      {:account_id => account_id}.merge(extra_params)
    end
  end

  class User < BaseResource
  end

end

