# frozen_string_literal: true

module GolfGenius
  # Base class for all Golf Genius API resources.
  # Provides common functionality for API objects.
  #
  # @abstract Subclass and define RESOURCE_PATH to create a new resource type.
  #
  # @example Creating a new resource (see Season, Category, Directory, Event for real examples)
  #   class MyResource < Resource
  #     RESOURCE_PATH = "/my_resource"
  #
  #     extend APIOperations::List
  #     extend APIOperations::Fetch
  #   end
  #
  # @see https://www.golfgenius.com/api/v2/docs Golf Genius API Documentation
  class Resource < GolfGeniusObject
    # Returns the API path for this resource type.
    # Subclasses must define RESOURCE_PATH constant.
    #
    # @return [String] The resource path (e.g., "/seasons")
    # @raise [NotImplementedError] If RESOURCE_PATH is not defined
    def self.resource_path
      raise NotImplementedError, "#{name} must define RESOURCE_PATH constant" unless const_defined?(:RESOURCE_PATH)

      const_get(:RESOURCE_PATH)
    end

    # Constructs a new resource instance from API response attributes.
    #
    # @param attributes [Hash] The attributes from the API response
    # @param api_key [String, nil] The API key used to fetch this resource
    # @return [Resource] The constructed resource instance
    def self.construct_from(attributes, api_key: nil)
      new(attributes, api_key: api_key)
    end

    # Refreshes this resource from the API.
    # Uses the API key that was used to originally fetch this resource.
    #
    # @return [self] The refreshed resource
    # @raise [ConfigurationError] If no API key is available
    def refresh
      response = APIOperations::Request.execute(
        method: :get,
        path: "#{self.class.resource_path}/#{id}",
        api_key: @api_key
      )

      @attributes = Util.symbolize_keys(response)
      self
    end
  end
end
