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
require "golf_genius/resources/category"
require "golf_genius/resources/directory"
require "golf_genius/resources/event"

# Golf Genius Ruby API client.
#
# A Ruby library for accessing the Golf Genius API v2, providing read-only
# access to seasons, categories, directories, and events.
#
# @example Basic configuration
#   GolfGenius.api_key = 'your_api_key'
#
# @example Block configuration
#   GolfGenius.configure do |config|
#     config.api_key = ENV['GOLF_GENIUS_API_KEY']
#     config.logger = Rails.logger
#   end
#
# @example Using resources directly
#   seasons = GolfGenius::Season.list
#   event = GolfGenius::Event.fetch('event_123')
#
# @example Using the client (for multiple API keys)
#   client = GolfGenius::Client.new(api_key: 'your_api_key')
#   seasons = client.seasons.list
#
# @see https://www.golfgenius.com/api/v2/docs Golf Genius API Documentation
module GolfGenius
  # Official Golf Genius API documentation URL
  API_DOCS_URL = "https://www.golfgenius.com/api/v2/docs"
end
