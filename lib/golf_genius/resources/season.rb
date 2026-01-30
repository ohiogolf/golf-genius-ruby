# frozen_string_literal: true

module GolfGenius
  # Represents a Golf Genius season.
  # Seasons are used to organize events by time period (e.g., "2026 Season").
  #
  # List parameters (optional): +:page+ (single page), +:api_key+. The API does not support
  # other filters for listing seasons.
  #
  # @example List all seasons
  #   seasons = GolfGenius::Season.list
  #   seasons.each { |s| puts s.name }
  #
  # @example Fetch a specific season
  #   season = GolfGenius::Season.fetch('season_123')
  #   puts season.name
  #   puts season.current
  #
  # @see https://www.golfgenius.com/api/v2/docs Golf Genius API Documentation
  class Season < Resource
    # API endpoint path for seasons
    RESOURCE_PATH = "/seasons"

    extend APIOperations::List
    extend APIOperations::Fetch
  end
end
