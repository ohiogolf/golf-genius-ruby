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
    # Production API base URL
    DEFAULT_BASE_URL = "https://www.golfgenius.com"
    # Staging API base URL (set +GOLF_GENIUS_ENV=staging+ or +base_url+ to use)
    STAGING_BASE_URL = "https://ggstest.com"

    # @return [String, nil] The API key for authenticating requests
    attr_accessor :api_key

    # @return [String] The base URL for API requests. Defaults from +GOLF_GENIUS_BASE_URL+ or
    #   +GOLF_GENIUS_ENV=staging+; otherwise production.
    attr_accessor :base_url

    # @return [Integer] Connection open timeout in seconds (default: 30)
    attr_reader :open_timeout

    # @return [Integer] Read timeout in seconds (default: 80)
    attr_reader :read_timeout

    # @return [Logger, nil] Logger instance for request/response logging
    attr_accessor :logger

    # @return [Symbol, nil] Log level (:debug, :info, :warn, :error)
    attr_accessor :log_level

    # @return [Boolean] When true, enables request/response logging to $stdout at :debug level (if logger not set)
    attr_accessor :debug

    # Tracks configuration version for connection cache invalidation
    # @api private
    attr_reader :version

    def initialize
      @api_key = nil
      @base_url = default_base_url_from_env
      @open_timeout = 30
      @read_timeout = 80
      @logger = nil
      @log_level = nil
      @debug = false
      @version = 0
    end

    # Inspect without exposing the API key.
    #
    # @return [String]
    def inspect
      api_key_display = @api_key.nil? ? "nil" : "[REDACTED-API-KEY]"
      "#<#{self.class} api_key=#{api_key_display} base_url=#{@base_url.inspect} " \
        "open_timeout=#{@open_timeout} read_timeout=#{@read_timeout} " \
        "logger=#{@logger.inspect} log_level=#{@log_level.inspect} debug=#{@debug} version=#{@version}>"
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

    def default_base_url_from_env
      url = ENV.fetch("GOLF_GENIUS_BASE_URL", nil)
      return url.strip if url.to_s.strip != ""

      return STAGING_BASE_URL if ENV["GOLF_GENIUS_ENV"].to_s.strip.casecmp("staging").zero?

      DEFAULT_BASE_URL
    end

    def increment_version
      @version += 1
    end
  end

  # Represents the current API environment (production, staging, or custom base URL).
  # Use {GolfGenius.env} to interrogate the active environment.
  #
  # @example In console
  #   GolfGenius.env           # => #<GolfGenius::Environment production base_url="https://www.golfgenius.com">
  #   GolfGenius.env.production?  # => true
  #   GolfGenius.env.staging?     # => false
  class Environment
    # @param base_url [String] Current configured base URL
    def self.for(base_url)
      new(base_url.to_s.strip)
    end

    def initialize(base_url)
      @base_url = base_url
    end

    # @return [Boolean] true when base URL is production (www.golfgenius.com)
    def production?
      @base_url == Configuration::DEFAULT_BASE_URL
    end

    # @return [Boolean] true when base URL is staging (ggstest.com)
    def staging?
      @base_url == Configuration::STAGING_BASE_URL
    end

    # @return [Boolean] true when base URL is neither production nor staging
    def custom?
      !production? && !staging?
    end

    # @return [String] "production", "staging", or "custom"
    def to_s
      if production?
        "production"
      elsif staging?
        "staging"
      else
        "custom"
      end
    end

    # @return [String] Human-readable inspect for console
    def inspect
      "#<#{self.class} #{self} base_url=#{@base_url.inspect}>"
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

    # Returns the current API environment for interrogation (production?, staging?, etc.).
    #
    # @return [Environment]
    # @example
    #   GolfGenius.env.production?  # => true
    #   GolfGenius.env.staging?    # => false
    #   GolfGenius.env.to_s        # => "production"
    def env
      Environment.for(configuration.base_url)
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

    # @!attribute [rw] debug
    #   When true, logs each request (method + full URL) and response status to $stdout at :debug level.
    #   If logger is already set, just sets log_level to :debug. Use for debugging API calls.
    #   @return [Boolean]
    def debug=(value)
      configuration.debug = value
      return unless value

      if configuration.logger.nil?
        require "logger"
        configuration.logger = Logger.new($stdout)
      end
      configuration.log_level = :debug
    end

    def debug
      configuration.debug
    end
  end
end
