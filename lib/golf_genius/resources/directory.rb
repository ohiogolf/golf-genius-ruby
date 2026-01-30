# frozen_string_literal: true

module GolfGenius
  # Represents a Golf Genius directory.
  # Directories are used to organize events.
  #
  # List parameters (optional): +:page+ (single page), +:api_key+. The API does not support
  # other filters for listing directories.
  #
  # @example List all directories
  #   directories = GolfGenius::Directory.list
  #   directories.each { |d| puts "#{d.name} - #{d.event_count} events" }
  #
  # @example Fetch a directory by id
  #   directory = GolfGenius::Directory.fetch('directory_123')
  #
  # @see https://www.golfgenius.com/api/v2/docs Golf Genius API Documentation
  class Directory < Resource
    # API endpoint path for directories
    RESOURCE_PATH = "/directories"

    extend APIOperations::List
    extend APIOperations::Fetch
  end
end
