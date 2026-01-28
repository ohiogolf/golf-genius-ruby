# frozen_string_literal: true

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

      # Converts nested hash into object with attribute accessors.
      #
      # @param data [Hash, Array, Object] The data to convert
      # @param class_name [String, nil] Optional class name to instantiate
      # @return [GolfGeniusObject, Array, Object] The converted object(s)
      def convert_to_golf_genius_object(data, class_name = nil)
        case data
        when Hash
          if class_name
            klass = GolfGenius.const_get(class_name)
            klass.construct_from(data)
          else
            GolfGeniusObject.construct_from(data)
          end
        when Array
          data.map { |item| convert_to_golf_genius_object(item, class_name) }
        else
          data
        end
      end

      # Encodes parameters for URL query string.
      #
      # @param params [Hash] Parameters to encode
      # @return [String] URL-encoded query string
      def encode_parameters(params)
        params.map do |key, value|
          "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
        end.join("&")
      end

      # Extracts data array from API response, handling various response formats.
      #
      # @param response [Hash, Array] The API response
      # @return [Array] The data array
      def extract_data_array(response)
        case response
        when Array
          response
        when Hash
          response["data"] || response[:data] || [response]
        else
          [response]
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

    # Returns a human-readable string representation.
    #
    # @return [String] Inspection string
    def inspect
      "#<#{self.class}:0x#{object_id.to_s(16)} #{@attributes.inspect}>"
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
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @attributes.key?(method_name) || super
    end

    protected

    # @return [String, nil] The API key used to fetch this object
    attr_reader :api_key

    private

    # Recursively converts a hash to plain Ruby hashes.
    def deep_to_h(obj)
      case obj
      when GolfGeniusObject
        deep_to_h(obj.attributes)
      when Hash
        obj.transform_values { |v| deep_to_h(v) }
      when Array
        obj.map { |v| deep_to_h(v) }
      else
        obj
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
