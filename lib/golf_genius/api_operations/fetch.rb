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
    #   event = Event.fetch_by(ggid: "zphsqa")  # by ggid
    #
    module Fetch
      # Declares which attributes are supported by +fetch_by+.
      # The given value is compared (as string) to each attribute; first match wins.
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
      # Matches +id+ (as string) against the +id+ attribute.
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

          found = results.find { |item| match_fetch_on?(item, [:id], id_str) }
          return found if found

          break if results.length < expected_page_size(params)

          page += 1
        end

        raise NotFoundError, "Resource not found: #{id_str}"
      end

      # Fetches a single resource by a supported attribute using the list endpoint.
      #
      # @param params [Hash] Search criteria and list filters (e.g. ggid: "zphsqa", api_key: "...")
      # @option params [Integer] :max_pages (20) Stop after this many pages if not found
      # @option params [String] :api_key Override the configured API key
      # @return [Resource] The matching resource
      # @raise [ArgumentError] If no supported attribute is provided
      # @raise [NotFoundError] If no resource matches within the page limit
      def fetch_by(params = {})
        params = params.dup
        max_pages = params.delete(:max_pages) || 20
        params.delete(:api_key)
        params.delete("api_key")
        match_keys = params.keys.map(&:to_sym)
        fetch_fields = fetch_match_fields
        search_keys = match_keys & fetch_fields
        raise ArgumentError, "fetch_by requires one of: #{fetch_fields.join(", ")}" if search_keys.empty?
        raise ArgumentError, "fetch_by accepts only one attribute" if search_keys.length > 1

        field = search_keys.first
        value = params.key?(field) ? params.delete(field) : params.delete(field.to_s)
        raise ArgumentError, "#{field} is required" if value.nil? || value.to_s.empty?
        raise ArgumentError, "Only #{fetch_fields.join(", ")} are supported" unless params.empty?

        return fetch(value, params.merge(max_pages: max_pages)) if field == :id

        value_str = value.to_s
        page = 1
        while page <= max_pages
          results = list(params.merge(page: page))
          raise NotFoundError, "Resource not found: #{field}=#{value_str}" if results.empty?

          found = results.find { |item| match_fetch_on?(item, [field], value_str) }
          return found if found

          break if results.length < expected_page_size(params)

          page += 1
        end

        raise NotFoundError, "Resource not found: #{field}=#{value_str}"
      end

      private

      def match_fetch_on?(item, fields, value_str)
        Array(fields).any? do |field|
          item.respond_to?(field) && item.public_send(field).to_s == value_str
        end
      end
    end
  end
end
