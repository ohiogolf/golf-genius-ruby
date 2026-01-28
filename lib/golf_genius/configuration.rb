# frozen_string_literal: true

module GolfGenius
  class Configuration
    attr_accessor :api_key, :base_url, :open_timeout, :read_timeout, :logger, :log_level

    def initialize
      @api_key = nil
      @base_url = "https://www.golfgenius.com"
      @open_timeout = 30
      @read_timeout = 80
      @logger = nil
      @log_level = nil
    end

    def api_base
      @base_url
    end
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    # Convenience accessors
    def api_key=(value)
      configuration.api_key = value
    end

    def api_key
      configuration.api_key
    end

    def base_url=(value)
      configuration.base_url = value
    end

    def base_url
      configuration.base_url
    end

    def logger=(value)
      configuration.logger = value
    end

    def logger
      configuration.logger
    end

    def log_level=(value)
      configuration.log_level = value
    end

    def log_level
      configuration.log_level
    end
  end
end
