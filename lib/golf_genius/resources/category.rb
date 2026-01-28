# frozen_string_literal: true

module GolfGenius
  # Represents a Golf Genius category.
  # Categories are used to organize and group events.
  #
  # @example List all categories
  #   categories = GolfGenius::Category.list
  #   categories.each { |c| puts "#{c.name} - #{c.event_count} events" }
  #
  # @example Fetch a specific category
  #   category = GolfGenius::Category.fetch('category_123')
  #   puts category.name
  #   puts category.color
  #
  # @see https://www.golfgenius.com/api/v2/docs Golf Genius API Documentation
  class Category < Resource
    # API endpoint path for categories
    RESOURCE_PATH = "/categories"

    extend APIOperations::List
    extend APIOperations::Fetch
  end
end
