# frozen_string_literal: true

module GolfGenius
  module APIOperations
    # Provides list functionality for resources.
    # Extend this module in resource classes that support listing.
    #
    # @example
    #   class Season < Resource
    #     extend APIOperations::List
    #   end
    #
    #   seasons = Season.list
    #   seasons = Season.list(page: 2, api_key: 'custom_key')
    module List
      # Lists resources from the API.
      #
      # @param params [Hash] Query parameters for filtering/pagination
      # @option params [Integer] :page Page number for paginated results
      # @option params [String] :api_key API key (uses configured key if not provided)
      #
      # @return [Array<Resource>] Array of resource instances
      #
      # @example List all seasons
      #   seasons = GolfGenius::Season.list
      #
      # @example List with pagination
      #   events = GolfGenius::Event.list(page: 2)
      #
      # @example List with custom API key
      #   seasons = GolfGenius::Season.list(api_key: 'custom_key')
      def list(params = {})
        params = params.dup
        api_key = params.delete(:api_key)

        response = Request.execute(
          method: :get,
          path: resource_path,
          params: params,
          api_key: api_key
        )

        data = Util.extract_data_array(response)
        data.map { |item| construct_from(item, api_key: api_key) }
      end

      # Iterates through all pages of results, yielding each item.
      # Automatically handles pagination by fetching subsequent pages.
      #
      # @param params [Hash] Query parameters for filtering
      # @option params [String] :api_key API key (uses configured key if not provided)
      # @yield [Resource] Each resource from all pages
      # @return [Enumerator] If no block given, returns an Enumerator
      #
      # @example Iterate through all events
      #   GolfGenius::Event.auto_paging_each do |event|
      #     puts event.name
      #   end
      #
      # @example With filtering
      #   GolfGenius::Event.auto_paging_each(season_id: 'abc123') do |event|
      #     process(event)
      #   end
      #
      # @note This method assumes the API uses page-based pagination.
      #   If the API doesn't support pagination, it will make a single request.
      def auto_paging_each(params = {}, &block)
        return enum_for(:auto_paging_each, params) unless block_given?

        params = params.dup
        api_key = params.delete(:api_key)
        page = params.delete(:page) || 1

        loop do
          results = list(params.merge(page: page, api_key: api_key))
          break if results.empty?

          results.each(&block)

          # If we got fewer results than expected, we've likely hit the last page
          # This is a heuristic - adjust based on actual API behavior
          break if results.length < expected_page_size(params)

          page += 1
        end
      end

      # Collects all results from all pages into a single array.
      #
      # @param params [Hash] Query parameters for filtering
      # @option params [String] :api_key API key (uses configured key if not provided)
      # @return [Array<Resource>] All resources from all pages
      #
      # @example Get all events
      #   all_events = GolfGenius::Event.list_all(season_id: 'abc123')
      #
      # @note Use with caution on large datasets as this loads everything into memory.
      def list_all(params = {})
        auto_paging_each(params).to_a
      end

      private

      # Returns the expected page size for pagination detection.
      # Override in subclasses if the API uses a different default.
      #
      # @param params [Hash] The request parameters
      # @return [Integer] Expected number of items per page
      def expected_page_size(params)
        params[:per_page] || params[:limit] || 25
      end
    end
  end
end
