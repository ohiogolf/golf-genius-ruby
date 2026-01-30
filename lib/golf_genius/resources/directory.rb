# frozen_string_literal: true

module GolfGenius
  # Represents a Golf Genius directory.
  # Business: A folder or list in the customer center where events appear (e.g. "All Leagues & Events").
  # An event can be in multiple directories.
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
  # @example List events in this directory
  #   directory.events
  #   directory.events(page: 1)
  #
  # @see https://www.golfgenius.com/api/v2/docs Golf Genius API Documentation
  class Directory < Resource
    # API endpoint path for directories
    RESOURCE_PATH = "/directories"

    extend APIOperations::List
    extend APIOperations::Fetch

    # Returns events in this directory. Same as Event.list(directory: self); accepts same params (e.g. page, archived).
    #
    # @param params [Hash] Optional list params (page, archived, api_key, etc.)
    # @return [Array<Event>]
    def events(params = {})
      params = params.dup
      params[:api_key] ||= (respond_to?(:api_key, true) ? send(:api_key) : nil)
      Event.list(params.merge(directory: self))
    end
  end
end
