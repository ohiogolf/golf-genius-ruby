# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    # Reset configuration before each test
    GolfGenius.configuration = GolfGenius::Configuration.new
  end

  def test_default_configuration
    config = GolfGenius::Configuration.new
    assert_nil config.api_key
    assert_equal "https://www.golfgenius.com", config.base_url
    assert_equal 30, config.open_timeout
    assert_equal 80, config.read_timeout
  end

  def test_configure_with_block
    GolfGenius.configure do |config|
      config.api_key = "test_key"
      config.base_url = "https://test.example.com"
    end

    assert_equal "test_key", GolfGenius.api_key
    assert_equal "https://test.example.com", GolfGenius.base_url
  end

  def test_convenience_accessors
    GolfGenius.api_key = "my_key"
    assert_equal "my_key", GolfGenius.api_key

    GolfGenius.base_url = "https://custom.example.com"
    assert_equal "https://custom.example.com", GolfGenius.base_url
  end
end
