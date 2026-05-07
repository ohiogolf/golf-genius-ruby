# frozen_string_literal: true

module GolfGenius
  class Scoreboard
    # Shared string/hash cleanup helpers used across detailed payload builders.
    module ValueNormalizer
      module_function

      def normalize_text(value)
        return nil if value.nil?

        value.to_s.gsub(/\s+/, " ").strip
      end

      def normalize_blank(value)
        normalized = normalize_text(value)
        normalized == "" ? nil : normalized
      end

      def normalize_hash(value)
        case value
        when nil
          {}
        when Hash
          value
        else
          value.respond_to?(:to_h) ? value.to_h : {}
        end
      end

      def field_value(fields, *keys)
        keys.each do |key|
          value = fields[key] || fields[key.to_s] || fields[key.to_sym]
          return value if value && value != ""
        end

        nil
      end
    end
  end
end
