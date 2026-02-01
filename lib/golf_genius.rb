# frozen_string_literal: true

require "cgi"
require "golf_genius/version"
require "golf_genius/configuration"
require "golf_genius/errors"
require "golf_genius/util"
require "golf_genius/api_operations/request"
require "golf_genius/api_operations/list"
require "golf_genius/api_operations/fetch"
require "golf_genius/api_operations/nested_resource"
require "golf_genius/resource"
require "golf_genius/client"
require "golf_genius/resources/season"
require "golf_genius/resources/directory"
require "golf_genius/resources/category"
require "golf_genius/resources/roster_member"
require "golf_genius/resources/handicap"
require "golf_genius/resources/tee"
require "golf_genius/resources/player"
require "golf_genius/resources/round"
require "golf_genius/resources/course"
require "golf_genius/resources/tournament"
require "golf_genius/resources/tournament_results"
require "golf_genius/resources/division"
require "golf_genius/resources/tee_sheet_player"
require "golf_genius/resources/tee_sheet_group"
require "golf_genius/resources/event"

# Golf Genius Ruby API client.
# A Ruby library for accessing the Golf Genius API v2.
#
# @see https://www.golfgenius.com/api/v2/docs Golf Genius API Documentation
module GolfGenius
  API_DOCS_URL = "https://www.golfgenius.com/api/v2/docs"

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

    # @return [String, nil] The API key for authenticating requests
    def api_key
      configuration.api_key
    end

    # @!attribute [rw] base_url
    #   @return [String] The base URL for API requests
    def base_url=(value)
      configuration.base_url = value
    end

    # @return [String] The base URL for API requests
    def base_url
      configuration.base_url
    end

    # Returns the current API environment for interrogation (production?, staging?, etc.).
    #
    # @return [Environment]
    def env
      Environment.for(configuration.base_url)
    end

    # @!attribute [rw] logger
    #   @return [Logger, nil] Logger instance for request/response logging
    def logger=(value)
      configuration.logger = value
    end

    # @return [Logger, nil] Logger instance for request/response logging
    def logger
      configuration.logger
    end

    # @!attribute [rw] log_level
    #   @return [Symbol, nil] Log level (:debug, :info, :warn, :error)
    def log_level=(value)
      configuration.log_level = value
    end

    # @return [Symbol, nil] Log level (:debug, :info, :warn, :error)
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

    # @return [Boolean] Whether debug logging is enabled
    def debug
      configuration.debug
    end
  end
end
