# frozen_string_literal: true

require "test_helper"

class GolfGeniusTest < Minitest::Test
  def test_version
    assert_equal "0.1.0", GolfGenius::VERSION
  end

  def test_module_methods
    assert_respond_to GolfGenius, :api_key=
    assert_respond_to GolfGenius, :api_key
    assert_respond_to GolfGenius, :configure
  end

  def test_resource_classes_exist
    assert defined?(GolfGenius::Season)
    assert defined?(GolfGenius::Category)
    assert defined?(GolfGenius::Directory)
    assert defined?(GolfGenius::Event)
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
end
