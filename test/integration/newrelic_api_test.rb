require File.dirname(__FILE__) + '/../test_helper'
require 'zlib'
require 'new_relic_api'

# This test runs against our integration server, which is loaded with fixture data.
class NewrelicApiTest < ActiveSupport::TestCase

  # Accounts may be identified either by their ID or by their license key.
  # This is the license key for the "gold" fixture in the New Relic fixture data.
  LICENSE_KEY = '8022da2f6d143de67e056741262a054547b43479'

  def setup
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

  def test_find_default
    account = NewRelicApi::Account.find(:first)
    assert_equal 'Gold', account.name
    assert_equal LICENSE_KEY, account.license_key
  end

  def test_account_find
    accounts = NewRelicApi::Account.find(:all)
    assert_equal 1, accounts.length
    assert_equal 'Gold', accounts.first.name
    assert_equal LICENSE_KEY, accounts.first.license_key
  end

  def test_account_show
    nr_account = NewRelicApi::Account.find(LICENSE_KEY)
    assert_not_nil nr_account

    account2 = NewRelicApi::Account.find(nr_account.id)
    assert_not_nil account2
  end

  def test_account_show_applications
    account = NewRelicApi::Account.find(LICENSE_KEY)
    assert_not_nil account

    apps = account.applications

    check_applications(apps)
    ui_app = apps.first

    # Unfortunately, if you ask for a non-existent app, you get a redirect right now.
    assert_raises ActiveResource::Redirection do
      account.applications(9999)
    end

    ui_app = account.applications(ui_app.id)
    assert_not_nil ui_app

    threshold_values = ui_app.threshold_values
    assert_equal 9, threshold_values.length
  end

  def test_application_health
    account = NewRelicApi::Account.application_health
    check_applications(account.applications)
  end

  def test_deployments
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

  def test_restricted_partner_account
    NewRelicApi.api_key = '9042da2f6d143de67e056741262a051234b43475'
    NewRelicApi.reset!

    account = NewRelicApi::Account.find('9042da2f6d143de67e056741262a051234b43475')
    assert_equal "Clouds 'R' Us", account.name
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
        assert [0, 1, 2, 3].include?(val.threshold_value), val.threshold_value
        assert ['Gray', 'Green', 'Yellow', 'Red'].include?(val.color_value), val.color_value

        assert_not_nil val.formatted_metric_value

        assert_not_nil val.metric_value
        #> 0 || val.name == 'Errors', val.name
      end
    end
  end

end
