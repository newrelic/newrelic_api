require File.dirname(__FILE__) + '/../test_helper'
require 'zlib'
require 'new_relic_api'

# This test runs against our integration server, which is loaded with fixture data.
class NewrelicApiTest < ActiveSupport::TestCase

  # Accounts may be identified either by their ID or by their license key.
  # This is the license key for the "gold" fixture in the New Relic fixture data.
  LICENSE_KEY = '8022da2f6d143de67e056741262a054547b43479'



  context "using the default base url" do
    setup do
      NewRelicApi.api_key = LICENSE_KEY
      NewRelicApi.host = nil
      NewRelicApi.reset!
    end

    should "set the default host endpoint to api.newrelic.com" do
      assert_equal "https://api.newrelic.com:443", NewRelicApi::Account.site_url
    end

    should "have a 'api/v1' prefix for accounts path" do
      assert_equal true, NewRelicApi::ACCOUNT_RESOURCE_PATH.start_with?('/api/v1')
    end
  end


  context "as a non-existing user in production" do
    setup do
      production_api_key = 'thisisawrongapikey'

      NewRelicApi.api_key = production_api_key
      NewRelicApi.reset!
    end

    should "raised a ForbiddenAccess exception when we make a request" do
      assert_raise(ActiveResource::ForbiddenAccess) do
        NewRelicApi::Account.find(:first)
      end
    end
  end


  context "using the integration endpoint" do
    setup do
      NewRelicApi.api_key = LICENSE_KEY
      if ENV['LOCAL']
        # Run your local instance in RAILS_ENV=test to load the fixture data
        NewRelicApi.host = 'localhost'
        NewRelicApi.port = 3000
      else
        NewRelicApi.host = 'integration.newrelic.com'
      end
      NewRelicApi.reset!
    end

    should "find default account" do
      account = NewRelicApi::Account.find(:first)
      assert_equal 'Gold', account.name
      assert_equal LICENSE_KEY, account.license_key
    end

    should "find an account" do
      accounts = NewRelicApi::Account.find(:all)
      assert_equal 1, accounts.length
      assert_equal 'Gold', accounts.first.name
      assert_equal LICENSE_KEY, accounts.first.license_key
    end

    should "get information about one specific account" do
      nr_account = NewRelicApi::Account.find(LICENSE_KEY)
      assert_not_nil nr_account

      account2 = NewRelicApi::Account.find(nr_account.id)
      assert_not_nil account2

      account = NewRelicApi::Account.find(LICENSE_KEY)
      assert_not_nil account

      apps = account.applications

      check_applications(apps)
      ui_app = apps.first

      assert_raises ActiveResource::ResourceNotFound do
        account.applications(9999)
      end

      ui_app = account.applications(ui_app.id)
      assert_not_nil ui_app

      threshold_values = ui_app.threshold_values
      assert_equal 9, threshold_values.length
    end

    should "get health of the account's applications" do
      account = NewRelicApi::Account.application_health
      check_applications(account.applications)
    end

    should "get application with no health" do
      NewRelicApi.api_key = '9042da2f6d143de67e056741262a051234b434659042'
      account = NewRelicApi::Account.application_health
      assert_equal 1, account.applications.length
      assert_equal 0, account.applications.first.threshold_values.length
    end

    should "deploy" do
      # lookup an app by name
      deployment = NewRelicApi::Deployment.create :appname => 'gold app'
      assert deployment.valid?, deployment.inspect

      # lookup an app by name
      deployment = NewRelicApi::Deployment.create :application_id => 'gold app'
      assert deployment.valid?, deployment.inspect

      account = NewRelicApi::Account.find(LICENSE_KEY)
      apps = account.applications
      application_id = apps.first.id

      # lookup by id won't work with appname
      deployment = NewRelicApi::Deployment.create :appname => application_id
      assert !deployment.valid?, deployment.inspect

      # lookup by id works with application_id
      deployment = NewRelicApi::Deployment.create :application_id => application_id
      assert deployment.valid?, deployment.inspect
    end

    should  "test_restricted_partner_account"  do
      NewRelicApi.api_key = '9042da2f6d143de67e056741262a051234b43475'
      NewRelicApi.reset!

      account = NewRelicApi::Account.find('9042da2f6d143de67e056741262a051234b43475')
      assert_equal "Clouds 'R' Us", account.name
    end

  end

  protected
  def check_applications(apps)
    app_names = apps.collect { |app| app.name }

    assert_equal 1, app_names.length
    assert_equal 'gold app', app_names.first

    apps.each do |app|
      threshold_values = app.threshold_values

      assert_equal 9, threshold_values.length
      threshold_values.each do |val|
        assert [0, 1, 2, 3].include?(val.threshold_value), val.threshold_value.to_s
        assert ['Gray', 'Green', 'Yellow', 'Red'].include?(val.color_value), val.color_value.to_s

        assert_not_nil val.formatted_metric_value

        assert_not_nil val.metric_value
        #> 0 || val.name == 'Errors', val.name
      end
    end
  end


end
