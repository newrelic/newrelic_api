require File.dirname(__FILE__) + '/../test_helper'
require 'zlib'
require 'new_relic_api'

# This test runs against our integration server, which is loaded with fixture data.
class NewrelicApiTest < ActiveSupport::TestCase  
  
  def setup
    NewRelicApi.host = 'integration.newrelic.com'
=begin    
    NewRelicApi.host = 'localhost'
    NewRelicApi.port = 3000
=end
    NewRelicApi.license_key = '8022da2f6d143de67e056741262a054547b43479'
    NewRelicApi.reset!
  end
  
  def test_account_find
    accounts = NewRelicApi::Account.find(:all)
    assert_equal 1, accounts.length
    assert_equal 'Gold', accounts.first.name
    assert_equal identify("gold"), accounts.first.id.to_i
  end

  def test_account_show
    nr_account = NewRelicApi::Account.find(identify('gold'))
    assert_not_nil nr_account
  end

  def test_account_show_applications
    account = NewRelicApi::Account.find(identify('gold'))
    assert_not_nil account
    
    apps = account.applications
    
    check_applications(apps)

    # Unfortunately, if you ask for a non-existent app, you get a redirect right now.
    assert_raises ActiveResource::Redirection do
      account.applications(9999)
    end
    
    ui_app = account.applications(identify('gold_cluster'))
    threshold_values = ui_app.threshold_values
    assert_equal 9, threshold_values.length
  end

  def test_application_health
    account = NewRelicApi::Account.application_health
    check_applications(account.applications)
  end
  
  protected
  def check_applications(apps)
    app_names = apps.collect {|app| app.name}

    assert_equal 1, app_names.length
    assert_equal 'gold app', app_names.first

    apps.each do |app|
      threshold_values = app.threshold_values
      
      assert_equal 9, threshold_values.length
      
      threshold_values.each do |val|
        assert [0, 1,2,3].include?(val.threshold_value), val.threshold_value
        assert ['Gray', 'Green', 'Yellow', 'Red'].include?(val.color_value), val.color_value
        
        assert_not_nil val.formatted_metric_value
        
        assert_not_nil val.metric_value 
        #> 0 || val.name == 'Errors', val.name
      end
    end
  end
  
  # Copied from the AR test fixture code.  These ids are generated in our integration server from
  # our test fixtures.
  MAX_ID = 2 ** 31 - 1
  def identify(label)
    Zlib.crc32(label.to_s) % MAX_ID
  end

end
