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
      # When :page is omitted, fetches all pages and returns the full array.
      # When :page is provided, returns only that page (single request).
      #
      # @param params [Hash] Query parameters for filtering/pagination
      # @option params [Integer] :page If present, return only this page (one request); if omitted, fetch all pages
      # @option params [String] :api_key API key (uses configured key if not provided)
      #
      # @return [Array<Resource>] Array of resource instances
      #
      # @example List all events (all pages)
      #   events = GolfGenius::Event.list(directory: dir)
      #
      # @example Single page only
      #   events = GolfGenius::Event.list(page: 2)
      #
      # @example List with custom API key
      #   seasons = GolfGenius::Season.list(api_key: 'custom_key')
      def list(params = {})
        return list_all(params) unless params.key?(:page)

        fetch_page(params)
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
        page = params.delete(:page)
        page = page_index_base if page.nil?
        previous_count = nil
        previous_first_id = nil

        loop do
          results = fetch_page(params.merge(page: page, api_key: api_key))
          break if results.empty?

          # If API doesn't support pagination or returns the same data for different page numbers,
          # stop before yielding duplicates (same first_id and count as previous page).
          first_id = results.first&.id
          break if previous_first_id && results.length == previous_count && first_id == previous_first_id

          previous_count = results.length
          previous_first_id = first_id

          results.each(&block)

          # Only treat as last page when caller passed explicit per_page/limit and we got fewer.
          requested_size = params[:per_page] || params[:limit]
          break if requested_size && results.length < requested_size

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

      # Fetches a single page of results (one API request).
      def fetch_page(params)
        params = params.dup
        api_key = params.delete(:api_key)
        request_params = Util.normalize_request_params(params)

        response = Request.execute(
          method: :get,
          path: resource_path,
          params: request_params,
          api_key: api_key
        )

        response_key = resource_path.to_s.sub(%r{\A/}, "")
        item_key = Util.singularize_resource_key(response_key)
        data = Util.extract_data_array(response, response_key: response_key)
        data.map do |item|
          attrs = Util.unwrap_list_item(item, item_key: item_key)
          construct_from(attrs, api_key: api_key)
        end
      end

      # Returns the expected page size for pagination detection.
      # Override in subclasses if the API uses a different default.
      #
      # @param params [Hash] The request parameters
      # @return [Integer] Expected number of items per page
      def expected_page_size(params)
        params[:per_page] || params[:limit] || 25
      end

      # First page index for pagination. Default is 1 (1-based). Override in subclasses if the API uses
      # a different first-page index.
      #
      # @return [Integer] First page number (default 1)
      def page_index_base
        1
      end
    end
  end
end
