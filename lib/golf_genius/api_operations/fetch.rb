# frozen_string_literal: true

module GolfGenius
  module APIOperations
    # Provides fetch-by-identifier using the list endpoint (API has no get-by-ID).
    # Resources can configure which attributes to match via +fetch_match_on+.
    #
    # @example Default: match on +id+ only
    #   class Season < Resource
    #     extend APIOperations::List
    #     extend APIOperations::Fetch
    #   end
    #   season = Season.fetch("season_123")
    #
    # @example Match on multiple attributes (e.g. id and ggid)
    #   class Event < Resource
    #     extend APIOperations::List
    #     extend APIOperations::Fetch
    #     fetch_match_on :id, :ggid
    #   end
    #   event = Event.fetch(171716)
    #   event = Event.fetch("zphsqa")  # by ggid
    #
    module Fetch
      # Declares which attributes to match when fetching by id.
      # The given +id+ is compared (as string) to each attribute; first match wins.
      #
      # @param fields [Symbol] Attribute names (e.g. +:id+, +:ggid+)
      # @return [void]
      def fetch_match_on(*fields)
        @fetch_match_fields = fields.freeze
      end

      # Returns the list of attributes used for matching in +fetch+ (default +[:id]+).
      #
      # @return [Array<Symbol>]
      def fetch_match_fields
        @fetch_match_fields || [:id]
      end

      # Fetches a single resource by id by listing pages until a match is found.
      # Matches +id+ (as string) against each attribute configured in +fetch_match_on+.
      #
      # @param id [String, Integer] Identifier (e.g. 171716, "season_123", "zphsqa")
      # @param params [Hash] Optional list filters and options
      # @option params [Integer] :max_pages (20) Stop after this many pages if not found
      # @option params [String] :api_key Override the configured API key
      # @return [Resource] The matching resource
      # @raise [NotFoundError] If no resource matches within the page limit
      def fetch(id, params = {})
        params = params.dup
        max_pages = params.delete(:max_pages) || 20
        id_str = id.to_s
        page = 1

        while page <= max_pages
          results = list(params.merge(page: page))
          raise NotFoundError, "Resource not found: #{id_str}" if results.empty?

          found = results.find { |item| match_fetch?(item, id_str) }
          return found if found

          break if results.length < expected_page_size(params)

          page += 1
        end

        raise NotFoundError, "Resource not found: #{id_str}"
      end

      private

      def match_fetch?(item, id_str)
        fetch_match_fields.any? do |field|
          item.respond_to?(field) && item.public_send(field).to_s == id_str
        end
      end
    end
  end
end
