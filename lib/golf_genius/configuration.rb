# frozen_string_literal: true

module GolfGenius
  # Configuration class for the Golf Genius API client.
  #
  # @example Configure using a block
  #   GolfGenius.configure do |config|
  #     config.api_key = 'your_api_key'
  #     config.logger = Rails.logger
  #   end
  #
  # @example Configure using direct assignment
  #   GolfGenius.api_key = 'your_api_key'
  #
  # @see https://www.golfgenius.com/api/v2/docs Golf Genius API Documentation
  class Configuration
    # @return [String, nil] The API key for authenticating requests
    attr_accessor :api_key

    # @return [String] The base URL for API requests (default: https://www.golfgenius.com)
    attr_accessor :base_url

    # @return [Integer] Connection open timeout in seconds (default: 30)
    attr_accessor :open_timeout

    # @return [Integer] Read timeout in seconds (default: 80)
    attr_accessor :read_timeout

    # @return [Logger, nil] Logger instance for request/response logging
    attr_accessor :logger

    # @return [Symbol, nil] Log level (:debug, :info, :warn, :error)
    attr_accessor :log_level

    # Tracks configuration version for connection cache invalidation
    # @api private
    attr_reader :version

    def initialize
      @api_key = nil
      @base_url = "https://www.golfgenius.com"
      @open_timeout = 30
      @read_timeout = 80
      @logger = nil
      @log_level = nil
      @version = 0
    end

    # Increments version when timeout settings change to invalidate connection cache
    # @api private
    def open_timeout=(value)
      @open_timeout = value
      increment_version
    end

    # Increments version when timeout settings change to invalidate connection cache
    # @api private
    def read_timeout=(value)
      @read_timeout = value
      increment_version
    end

    private

    def increment_version
      @version += 1
    end
  end

  class << self
    attr_writer :configuration

    # Returns the current configuration, creating a new one if necessary.
    #
    # @return [Configuration] The current configuration instance
    def configuration
      @configuration ||= Configuration.new
    end

    # Yields the configuration object for modification.
    #
    # @yield [Configuration] The configuration instance
    # @return [void]
    #
    # @example
    #   GolfGenius.configure do |config|
    #     config.api_key = ENV['GOLF_GENIUS_API_KEY']
    #     config.logger = Rails.logger
    #   end
    def configure
      yield(configuration)
    end

    # Resets the configuration to defaults.
    # Useful for testing or reconfiguring the client.
    #
    # @return [Configuration] The new configuration instance
    def reset_configuration!
      @configuration = Configuration.new
    end

    # @!attribute [rw] api_key
    #   @return [String, nil] The API key for authenticating requests
    def api_key=(value)
      configuration.api_key = value
    end

    def api_key
      configuration.api_key
    end

    # @!attribute [rw] base_url
    #   @return [String] The base URL for API requests
    def base_url=(value)
      configuration.base_url = value
    end

    def base_url
      configuration.base_url
    end

    # @!attribute [rw] logger
    #   @return [Logger, nil] Logger instance for request/response logging
    def logger=(value)
      configuration.logger = value
    end

    def logger
      configuration.logger
    end

    # @!attribute [rw] log_level
    #   @return [Symbol, nil] Log level (:debug, :info, :warn, :error)
    def log_level=(value)
      configuration.log_level = value
    end

    def log_level
      configuration.log_level
    end
  end
end
