# frozen_string_literal: true

module GolfGenius
  # Represents a Golf Genius season.
  # Business: A time bucket for the calendar (e.g. "2026 Season"). Used to filter and group events by year or period.
  #
  # List parameters (optional): +:page+ (single page), +:api_key+. The API does not support
  # other filters for listing seasons.
  #
  # @example List all seasons
  #   seasons = GolfGenius::Season.list
  #   seasons.each { |s| puts s.name }
  #
  # @example Fetch a season by id
  #   season = GolfGenius::Season.fetch('season_123')
  #   season = GolfGenius::Season.fetch_by(id: 'season_123')
  #
  # @see https://www.golfgenius.com/api/v2/docs Golf Genius API Documentation
  class Season < Resource
    # API endpoint path for seasons
    RESOURCE_PATH = "/seasons"

    extend APIOperations::List
    extend APIOperations::Fetch
  end
end
