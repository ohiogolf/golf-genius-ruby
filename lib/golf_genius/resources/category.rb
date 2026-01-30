# frozen_string_literal: true

module GolfGenius
  # Represents a Golf Genius category.
  # Business: A label for types of events (e.g. "Member Events", "Championships"). Used to filter and display
  # events by kind.
  #
  # List parameters (optional): +:page+ (single page), +:api_key+. The API does not support
  # other filters for listing categories.
  #
  # @example List all categories
  #   categories = GolfGenius::Category.list
  #   categories.each { |c| puts "#{c.name} - #{c.event_count} events" }
  #
  # @example Fetch a category by id
  #   category = GolfGenius::Category.fetch('category_123')
  #
  # @example List events in this category
  #   category.events
  #   category.events(page: 1)
  #
  # @see https://www.golfgenius.com/api/v2/docs Golf Genius API Documentation
  class Category < Resource
    # API endpoint path for categories
    RESOURCE_PATH = "/categories"

    extend APIOperations::List
    extend APIOperations::Fetch

    # Returns events in this category. Same as Event.list(category: self); accepts same params (e.g. page, archived).
    #
    # @param params [Hash] Optional list params (page, archived, api_key, etc.)
    # @return [Array<Event>]
    def events(params = {})
      params = params.dup
      params[:api_key] ||= (respond_to?(:api_key, true) ? send(:api_key) : nil)
      Event.list(params.merge(category: self))
    end
  end
end
