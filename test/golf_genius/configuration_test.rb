# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    GolfGenius.reset_configuration!
  end

  def teardown
    GolfGenius.reset_configuration!
  end

  def test_default_configuration
    config = GolfGenius::Configuration.new

    assert_nil config.api_key
    assert_equal "https://www.golfgenius.com", config.base_url
    assert_equal 30, config.open_timeout
    assert_equal 80, config.read_timeout
    assert_nil config.logger
    assert_nil config.log_level
  end

  def test_configure_with_block
    GolfGenius.configure do |config|
      config.api_key = "test_key"
      config.base_url = "https://test.example.com"
      config.open_timeout = 60
      config.read_timeout = 120
    end

    assert_equal "test_key", GolfGenius.api_key
    assert_equal "https://test.example.com", GolfGenius.base_url
    assert_equal 60, GolfGenius.configuration.open_timeout
    assert_equal 120, GolfGenius.configuration.read_timeout
  end

  def test_convenience_accessors
    GolfGenius.api_key = "my_key"

    assert_equal "my_key", GolfGenius.api_key

    GolfGenius.base_url = "https://custom.example.com"

    assert_equal "https://custom.example.com", GolfGenius.base_url
  end

  def test_reset_configuration
    GolfGenius.api_key = "test_key"
    GolfGenius.base_url = "https://custom.example.com"

    GolfGenius.reset_configuration!

    assert_nil GolfGenius.api_key
    assert_equal "https://www.golfgenius.com", GolfGenius.base_url
  end

  def test_configuration_version_increments_on_timeout_change
    config = GolfGenius::Configuration.new
    initial_version = config.version

    config.open_timeout = 60

    assert_equal initial_version + 1, config.version

    config.read_timeout = 120

    assert_equal initial_version + 2, config.version
  end

  def test_logger_configuration
    logger = Logger.new($stdout)
    GolfGenius.logger = logger
    GolfGenius.log_level = :debug

    assert_equal logger, GolfGenius.logger
    assert_equal :debug, GolfGenius.log_level
  end
end
