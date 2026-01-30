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
require "golf_genius/resources/round"
require "golf_genius/resources/course"
require "golf_genius/resources/tournament"
require "golf_genius/resources/division"
require "golf_genius/resources/event"

# Golf Genius Ruby API client.
# A Ruby library for accessing the Golf Genius API v2.
#
# @see https://www.golfgenius.com/api/v2/docs Golf Genius API Documentation
module GolfGenius
  API_DOCS_URL = "https://www.golfgenius.com/api/v2/docs"

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end

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

    def env
      Environment.for(configuration.base_url)
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
