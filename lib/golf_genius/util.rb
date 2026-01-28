# frozen_string_literal: true

module GolfGenius
  module Util
    # Converts keys in a hash to symbols recursively
    def self.symbolize_keys(hash)
      case hash
      when Hash
        hash.transform_keys(&:to_sym).transform_values { |v| symbolize_keys(v) }
      when Array
        hash.map { |v| symbolize_keys(v) }
      else
        hash
      end
    end

    # Converts nested hash into object with attribute accessors
    def self.convert_to_golf_genius_object(data, class_name = nil)
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

    # Encodes parameters for URL query string
    def self.encode_parameters(params)
      params.map do |key, value|
        "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
      end.join("&")
    end

    # Logs a message if logger is configured
    def self.log(level, message)
      logger = GolfGenius.logger
      return unless logger

      log_level = GolfGenius.log_level || :info
      return if [:debug, :info, :warn, :error].index(level) < [:debug, :info, :warn, :error].index(log_level)

      logger.send(level, message)
    end
  end

  # Generic Golf Genius object for unknown types
  class GolfGeniusObject
    attr_reader :attributes

    def initialize(attributes = {})
      # Symbolize keys first, then convert nested structures
      symbolized = Util.symbolize_keys(attributes)
      @attributes = convert_nested_values(symbolized)
    end

    def self.construct_from(attributes)
      new(attributes)
    end

    def to_h
      @attributes
    end

    def to_hash
      to_h
    end

    def inspect
      "#<#{self.class}:0x#{object_id.to_s(16)} #{@attributes.inspect}>"
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

    private

    # Convert nested hashes and arrays to GolfGeniusObjects
    # This only converts the VALUES in the hash, not the hash itself
    def convert_nested_values(hash)
      hash.transform_values do |value|
        convert_value(value)
      end
    end

    def convert_value(value)
      case value
      when Hash
        # Convert nested hash to a GolfGeniusObject
        GolfGeniusObject.construct_from(value)
      when Array
        # Convert each array element
        value.map { |item| convert_value(item) }
      else
        value
      end
    end
  end
end
