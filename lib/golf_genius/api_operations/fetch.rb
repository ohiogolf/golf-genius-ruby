# frozen_string_literal: true

module GolfGenius
  module APIOperations
    # Provides fetch functionality for resources.
    # Extend this module in resource classes that support fetching by ID.
    #
    # @example
    #   class Season < Resource
    #     extend APIOperations::Fetch
    #   end
    #
    #   season = Season.fetch('season_id')
    module Fetch
      # Fetches a single resource by ID.
      #
      # @param id [String] The resource ID
      # @param params [Hash] Additional query parameters
      # @option params [String] :api_key API key (uses configured key if not provided)
      #
      # @return [Resource] The fetched resource instance
      #
      # @raise [NotFoundError] If the resource is not found
      #
      # @example Fetch a season
      #   season = GolfGenius::Season.fetch('season_123')
      #
      # @example Fetch with custom API key
      #   season = GolfGenius::Season.fetch('season_123', api_key: 'custom_key')
      def fetch(id, params = {})
        params = params.dup
        api_key = params.delete(:api_key)

        response = Request.execute(
          method: :get,
          path: "#{resource_path}/#{id}",
          params: params,
          api_key: api_key
        )

        construct_from(response, api_key: api_key)
      end
    end
  end
end
