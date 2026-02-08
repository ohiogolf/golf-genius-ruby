# frozen_string_literal: true

require "time"

module GolfGenius
  # Utility methods for the Golf Genius gem.
  # @api private
  module Util
    class << self
      # Converts a string key to snake_case for Ruby attribute access.
      # Examples: "GGID" => "ggid", "handicapNetworkId" => "handicap_network_id".
      #
      # @param key [String, Symbol] The key to convert
      # @return [String] The snake_cased key
      def snake_case_key(key)
        str = key.to_s
        return str if str.empty?

        snake = str
                .gsub(/([A-Z]+)([A-Z][a-z])/, "\\1_\\2")
                .gsub(/([a-z\d])([A-Z])/, "\\1_\\2")
                .tr("-", "_")
        snake.downcase
      end

      # Converts keys in a hash to symbols recursively.
      #
      # @param hash [Hash, Array, Object] The object to process
      # @return [Hash, Array, Object] The processed object with symbolized keys
      def symbolize_keys(hash)
        case hash
        when Hash
          hash.transform_keys { |k| snake_case_key(k).to_sym }
              .transform_values { |v| symbolize_keys(v) }
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
      # - Accepts both :resource and :resource_id forms (e.g., :event or :event_id)
      # - Both forms map to the same API parameter name (e.g., "event")
      # - Extracts .id from GolfGeniusObject values (so you can pass objects directly)
      #
      # Supported parameter pairs:
      # - directory / directory_id → directory
      # - season / season_id → season
      # - category / category_id → category
      # - event / event_id → event
      # - round / round_id → round
      # - tournament / tournament_id → tournament
      # - player / player_id → player
      # - course / course_id → course
      # - division / division_id → division
      # - handicap / handicap_id → handicap
      # - roster_member / roster_member_id → roster_member
      # - tee / tee_id → tee
      #
      # @param params [Hash] Raw params (e.g. event: event_obj, round_id: "123")
      # @return [Hash] Params ready for the API (event: "event_123", round: "123")
      def normalize_request_params(params)
        # Map both :resource and :resource_id to the API param name
        to_api_key = {
          directory: :directory, directory_id: :directory,
          season: :season, season_id: :season,
          category: :category, category_id: :category,
          event: :event, event_id: :event,
          round: :round, round_id: :round,
          tournament: :tournament, tournament_id: :tournament,
          player: :player, player_id: :player,
          course: :course, course_id: :course,
          division: :division, division_id: :division,
          handicap: :handicap, handicap_id: :handicap,
          roster_member: :roster_member, roster_member_id: :roster_member,
          tee: :tee, tee_id: :tee,
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
      rescue ArgumentError => e
        log(:warn, "Failed to parse date/time value '#{value}': #{e.message}")
        value
      end

      # Returns true if the attribute key looks like a date/time (e.g. created_at, date, start_date).
      #
      # @param key [String, Symbol] Attribute name to test
      # @return [Boolean] True if the key represents a date/time attribute
      def date_attribute?(key)
        s = key.to_s
        s == "date" || s.end_with?("_at") || s.end_with?("_date")
      end

      # Coerces a value to true or false for predicate methods (e.g. deleted? -> deleted).
      #
      # @param value [Object] Value to coerce
      # @return [Boolean] Coerced boolean value
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
  # Provides attribute accessors defined from the API response keys.
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
    # @return [Hash] The raw API attributes before normalization
    attr_reader :raw_attributes

    # Creates a new GolfGeniusObject from attributes.
    #
    # @param attributes [Hash] The attributes hash
    # @param api_key [String, nil] The API key used to fetch this object
    def initialize(attributes = {}, api_key: nil)
      @api_key = api_key
      @raw_attributes = attributes.is_a?(Hash) ? attributes.dup : attributes
      # Symbolize keys first, then convert nested structures
      symbolized = Util.symbolize_keys(attributes)
      @attributes = convert_nested_values(symbolized)
      parse_date_attributes!
      self.class.define_attribute_methods!(@attributes.keys)
    end

    # Constructs a new object from attributes.
    #
    # @param attributes [Hash] The attributes hash
    # @param api_key [String, nil] The API key used to fetch this object
    # @return [GolfGeniusObject] The constructed object
    def self.construct_from(attributes, api_key: nil)
      new(attributes, api_key: api_key)
    end

    # Defines attribute reader and predicate methods for the provided keys.
    #
    # @param keys [Enumerable<Symbol, String>, Hash] Attribute keys or alias map
    def self.define_attribute_methods!(keys)
      pairs = normalize_attribute_pairs(keys)

      pairs.each do |method_key, attribute_key|
        method_name = method_key.to_sym
        attr_name = attribute_key.to_sym
        next if method_name.to_s.empty?
        next if method_defined?(method_name) || private_method_defined?(method_name)

        define_method(method_name) { @attributes[attr_name] }

        predicate = :"#{method_name}?"
        next if method_name.to_s.end_with?("?")
        next if method_defined?(predicate) || private_method_defined?(predicate)

        define_method(predicate) { Util.coerce_boolean?(@attributes[attr_name]) }
      end
    end

    # Converts the object to a plain Ruby hash, recursively converting nested objects.
    #
    # @param raw [Boolean] Return the raw API attributes without normalization (default: false)
    # @return [Hash] The attributes as a plain hash
    def to_h(raw: false)
      return deep_to_h_value(@raw_attributes, aliases: false) if raw

      alias_map = self.class.attribute_aliases_by_attr
      @attributes.each_with_object({}) do |(key, value), out|
        display_key = alias_map[key] || key
        out[display_key] = deep_to_h_value(value, aliases: true)
      end
    end

    # Alias for to_h.
    #
    # @return [Hash] The attributes as a plain hash
    def to_hash
      to_h
    end

    # Returns a JSON representation of the object.
    #
    # @param raw [Boolean] Return the raw API attributes without normalization (default: false)
    # @return [String] JSON string
    def to_json(raw: false, **args)
      to_h(raw: raw).to_json(**args)
    end

    # Returns a human-readable string representation (compact, scalar attributes only).
    # Nested objects are omitted so console output stays readable.
    #
    # @return [String] Inspection string
    def inspect
      pairs = @attributes.filter_map do |key, value|
        next if value.is_a?(GolfGeniusObject)
        next if value.is_a?(Array) || value.is_a?(Hash)

        display_key = self.class.attribute_aliases_by_attr[key] || key
        "#{display_key}=#{value.inspect}"
      end
      pairs = reorder_inspect_pairs(pairs)
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

    private

    def reorder_inspect_pairs(pairs)
      id_index = pairs.index { |pair| pair.start_with?("id=") }
      return pairs if id_index.nil? || id_index.zero?

      id_pair = pairs.delete_at(id_index)
      [id_pair, *pairs]
    end

    protected

    # @return [String, nil] The API key used to fetch this object
    attr_reader :api_key

    # Returns a typed association for an embedded attribute.
    #
    # @param attr_key [Symbol] The attribute key to access
    # @param klass [Class] The class to construct if needed
    # @return [Object, nil] Instance of +klass+ or nil
    def typed_value_object(attr_key, klass)
      raw = @attributes[attr_key]
      return nil if raw.nil?
      return raw if raw.is_a?(klass)

      attrs = raw.respond_to?(:to_h) ? raw.to_h : raw
      return raw unless attrs.is_a?(Hash) && !attrs.empty?

      klass.construct_from(attrs, api_key: api_key)
    end

    class << self
      def attribute_aliases_by_attr
        @attribute_aliases_by_attr ||= {}
      end

      private

      def normalize_attribute_pairs(keys)
        return Array(keys).map { |key| [key, key] } unless keys.is_a?(Hash)

        normalized = keys.each_with_object({}) do |(method_key, attribute_key), out|
          out[method_key.to_sym] = attribute_key.to_sym
        end
        attribute_aliases_by_attr.merge!(normalized.invert)
        normalized
      end
    end

    private

    # Recursively converts a hash to plain Ruby hashes. Time values become ISO8601 strings for JSON.
    #
    # @param obj [Object] Object to convert
    # @param aliases [Boolean] Whether to use attribute aliases (unused for raw conversion)
    # @return [Object] Converted value
    def deep_to_h_value(obj, aliases: true)
      case obj
      when GolfGeniusObject
        obj.to_h
      when Hash
        obj.transform_values { |v| deep_to_h_value(v, aliases: aliases) }
      when Array
        obj.map { |v| deep_to_h_value(v, aliases: aliases) }
      when Time
        obj.iso8601
      else
        obj
      end
    end

    # Parses string values for date/time attributes in place.
    #
    # @return [void]
    def parse_date_attributes!
      @attributes.each_key do |key|
        next unless Util.date_attribute?(key)

        val = @attributes[key]
        @attributes[key] = Util.parse_time(val) if val.is_a?(String)
      end
    end

    # Convert nested hashes and arrays to GolfGeniusObjects.
    # This only converts the VALUES in the hash, not the hash itself.
    #
    # @param hash [Hash] The hash with nested values
    # @return [Hash] Hash with nested values converted
    def convert_nested_values(hash)
      hash.transform_values do |value|
        convert_value(value)
      end
    end

    # Converts nested hashes and arrays to GolfGeniusObject instances.
    #
    # @param value [Object] The value to convert
    # @return [Object] Converted value
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
