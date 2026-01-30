# frozen_string_literal: true

require "time"

module GolfGenius
  # Utility methods for the Golf Genius gem.
  # @api private
  module Util
    class << self
      # Converts keys in a hash to symbols recursively.
      #
      # @param hash [Hash, Array, Object] The object to process
      # @return [Hash, Array, Object] The processed object with symbolized keys
      def symbolize_keys(hash)
        case hash
        when Hash
          hash.transform_keys(&:to_sym).transform_values { |v| symbolize_keys(v) }
        when Array
          hash.map { |v| symbolize_keys(v) }
        else
          hash
        end
      end

      # Extracts data array from API response, handling various response formats.
      # Golf Genius API may return { "data" => [...] } or { "directories" => [...] } etc.
      #
      # @param response [Hash, Array] The API response
      # @param response_key [String, Symbol, nil] Optional key for the array (e.g. "directories")
      # @return [Array] The data array
      def extract_data_array(response, response_key: nil)
        case response
        when Array
          response
        when Hash
          response["data"] || response[:data] ||
            (response_key && (response[response_key.to_s] || response[response_key.to_s.to_sym])) ||
            [response]
        else
          [response]
        end
      end

      # Unwraps a list item if the API wraps it in a singular key (e.g. { "directory" => {...} }).
      #
      # @param item [Hash, Object] A single item from the list array
      # @param item_key [String, Symbol, nil] Singular key used by the API (e.g. "directory")
      # @return [Hash, Object] The inner attributes hash or the item unchanged
      def unwrap_list_item(item, item_key: nil)
        return item unless item_key && item.is_a?(Hash) && item.size == 1

        key_str = item_key.to_s
        key_sym = item_key.to_s.to_sym
        return item[key_str] if item.key?(key_str)
        return item[key_sym] if item.key?(key_sym)

        item
      end

      # Returns singular form of a plural resource name for API response keys.
      #
      # @param plural [String] e.g. "directories", "seasons", "categories", "events"
      # @return [String] e.g. "directory", "season", "category", "event"
      def singularize_resource_key(plural)
        return plural if plural.nil? || plural.empty?

        s = plural.to_s
        if s.end_with?("ies")
          "#{s[0..-4]}y"
        elsif s.end_with?("s") && !s.end_with?("ss")
          s[0..-2]
        else
          s
        end
      end

      # Normalizes request params so resource objects and friendly keys work.
      # - Accepts :directory / :directory_id, :season / :season_id, :category / :category_id (all map to API key)
      # - API expects query param names "directory", "season", "category" (per docs URL template)
      # - Replaces GolfGeniusObject values with their .id (so you can pass a Directory, etc.)
      #
      # @param params [Hash] Raw params (e.g. directory: dir_obj, season: season_obj)
      # @return [Hash] Params ready for the API (directory: "123", season: "456")
      def normalize_request_params(params)
        to_api_key = {
          directory: :directory, directory_id: :directory,
          season: :season, season_id: :season,
          category: :category, category_id: :category,
        }

        params.each_with_object({}) do |(key, value), out|
          api_key = to_api_key[key] || key
          out[api_key] = value.is_a?(GolfGeniusObject) ? value.id : value
        end
      end

      # Parses a value as a Time if it is a date/time string (e.g. from API).
      # Returns the value unchanged if it's not a string, is empty, or fails to parse.
      #
      # @param value [Object] Usually a string like "2017-08-03 10:15:18 -0400" or "2017-09-01"
      # @return [Time, Object] Parsed Time or original value
      def parse_time(value)
        return value unless value.is_a?(String) && !value.strip.empty?

        Time.parse(value)
      rescue ArgumentError
        value
      end

      # Returns true if the attribute key looks like a date/time (e.g. created_at, date, start_date).
      def date_attribute?(key)
        s = key.to_s
        s == "date" || s.end_with?("_at") || s.end_with?("_date")
      end

      # Coerces a value to true or false for predicate methods (e.g. deleted? -> deleted).
      def coerce_boolean?(value)
        case value
        when true then true
        when false, nil then false
        when String then value.strip.downcase == "true"
        else
          !!value
        end
      end

      # Logs a message if logger is configured.
      #
      # @param level [Symbol] Log level (:debug, :info, :warn, :error)
      # @param message [String] The message to log
      # @return [void]
      def log(level, message)
        logger = GolfGenius.logger
        return unless logger

        log_level = GolfGenius.log_level || :info
        levels = %i[debug info warn error]
        return if levels.index(level) < levels.index(log_level)

        logger.send(level, message)
      end
    end
  end

  # Generic Golf Genius object for API responses.
  # Provides dynamic attribute access via method_missing.
  #
  # @example Accessing attributes
  #   obj = GolfGeniusObject.construct_from(id: "123", name: "Test")
  #   obj.id   # => "123"
  #   obj.name # => "Test"
  #
  # @example Converting to hash
  #   obj.to_h # => {id: "123", name: "Test"}
  class GolfGeniusObject
    # @return [Hash] The raw attributes hash
    attr_reader :attributes

    # Creates a new GolfGeniusObject from attributes.
    #
    # @param attributes [Hash] The attributes hash
    # @param api_key [String, nil] The API key used to fetch this object
    def initialize(attributes = {}, api_key: nil)
      @api_key = api_key
      # Symbolize keys first, then convert nested structures
      symbolized = Util.symbolize_keys(attributes)
      @attributes = convert_nested_values(symbolized)
      parse_date_attributes!
    end

    # Constructs a new object from attributes.
    #
    # @param attributes [Hash] The attributes hash
    # @param api_key [String, nil] The API key used to fetch this object
    # @return [GolfGeniusObject] The constructed object
    def self.construct_from(attributes, api_key: nil)
      new(attributes, api_key: api_key)
    end

    # Converts the object to a plain Ruby hash, recursively converting nested objects.
    #
    # @return [Hash] The attributes as a plain hash
    def to_h
      deep_to_h(@attributes)
    end

    # Alias for to_h.
    #
    # @return [Hash] The attributes as a plain hash
    def to_hash
      to_h
    end

    # Returns a JSON representation of the object.
    #
    # @return [String] JSON string
    def to_json(*args)
      to_h.to_json(*args)
    end

    # Returns a human-readable string representation (compact, scalar attributes only).
    # Nested objects are omitted so console output stays readable.
    #
    # @return [String] Inspection string
    def inspect
      pairs = @attributes.filter_map do |key, value|
        next if value.is_a?(GolfGeniusObject)
        next if value.is_a?(Array) || value.is_a?(Hash)

        "#{key}=#{value.inspect}"
      end
      "#<#{self.class} #{pairs.join(" ")}>"
    end

    # Checks if an attribute exists.
    #
    # @param key [Symbol, String] The attribute name
    # @return [Boolean] True if the attribute exists
    def key?(key)
      @attributes.key?(key.to_sym)
    end

    # Gets an attribute value by key.
    #
    # @param key [Symbol, String] The attribute name
    # @return [Object, nil] The attribute value
    def [](key)
      @attributes[key.to_sym]
    end

    def method_missing(method_name, *args)
      if @attributes.key?(method_name)
        @attributes[method_name]
      elsif method_name.end_with?("?") && args.empty?
        base = method_name.to_s.chomp("?").to_sym
        @attributes.key?(base) ? Util.coerce_boolean?(@attributes[base]) : super
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      return true if @attributes.key?(method_name)
      return true if method_name.end_with?("?") && @attributes.key?(method_name.to_s.chomp("?").to_sym)

      super
    end

    protected

    # @return [String, nil] The API key used to fetch this object
    attr_reader :api_key

    private

    # Recursively converts a hash to plain Ruby hashes. Time values become ISO8601 strings for JSON.
    def deep_to_h(obj)
      case obj
      when GolfGeniusObject
        deep_to_h(obj.attributes)
      when Hash
        obj.transform_values { |v| deep_to_h(v) }
      when Array
        obj.map { |v| deep_to_h(v) }
      when Time
        obj.iso8601
      else
        obj
      end
    end

    def parse_date_attributes!
      @attributes.each_key do |key|
        next unless Util.date_attribute?(key)

        val = @attributes[key]
        @attributes[key] = Util.parse_time(val) if val.is_a?(String)
      end
    end

    # Convert nested hashes and arrays to GolfGeniusObjects.
    # This only converts the VALUES in the hash, not the hash itself.
    def convert_nested_values(hash)
      hash.transform_values do |value|
        convert_value(value)
      end
    end

    def convert_value(value)
      case value
      when Hash
        # Convert nested hash to a GolfGeniusObject
        GolfGeniusObject.construct_from(value, api_key: @api_key)
      when Array
        # Convert each array element
        value.map { |item| convert_value(item) }
      else
        value
      end
    end
  end
end
