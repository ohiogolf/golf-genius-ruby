# frozen_string_literal: true

require "test_helper"

class GolfGeniusTest < Minitest::Test
  def test_version
    assert_equal "0.1.0", GolfGenius::VERSION
  end

  def test_api_docs_url_constant
    assert_equal "https://www.golfgenius.com/api/v2/docs", GolfGenius::API_DOCS_URL
  end

  def test_module_methods
    assert_respond_to GolfGenius, :api_key=
    assert_respond_to GolfGenius, :api_key
    assert_respond_to GolfGenius, :configure
    assert_respond_to GolfGenius, :reset_configuration!
    assert_respond_to GolfGenius, :base_url
    assert_respond_to GolfGenius, :base_url=
    assert_respond_to GolfGenius, :logger
    assert_respond_to GolfGenius, :logger=
    assert_respond_to GolfGenius, :log_level
    assert_respond_to GolfGenius, :log_level=
  end

  def test_resource_classes_exist
    assert defined?(GolfGenius::Season)
    assert defined?(GolfGenius::Category)
    assert defined?(GolfGenius::Directory)
    assert defined?(GolfGenius::Event)
  end

  def test_resource_classes_inherit_from_resource
    assert GolfGenius::Season < GolfGenius::Resource
    assert GolfGenius::Category < GolfGenius::Resource
    assert GolfGenius::Directory < GolfGenius::Resource
    assert GolfGenius::Event < GolfGenius::Resource
  end

  def test_error_classes_exist
    assert defined?(GolfGenius::GolfGeniusError)
    assert defined?(GolfGenius::AuthenticationError)
    assert defined?(GolfGenius::NotFoundError)
    assert defined?(GolfGenius::ValidationError)
    assert defined?(GolfGenius::RateLimitError)
    assert defined?(GolfGenius::ServerError)
    assert defined?(GolfGenius::ConnectionError)
    assert defined?(GolfGenius::ConfigurationError)
  end

  def test_client_class_exists
    assert defined?(GolfGenius::Client)
  end

  def test_api_operations_modules_exist
    assert defined?(GolfGenius::APIOperations::Request)
    assert defined?(GolfGenius::APIOperations::List)
    assert defined?(GolfGenius::APIOperations::Fetch)
    assert defined?(GolfGenius::APIOperations::NestedResource)
  end
end
