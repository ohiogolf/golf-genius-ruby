# frozen_string_literal: true

require_relative "affiliation_parser"
require_relative "schema_values"
require_relative "value_normalizer"

module GolfGenius
  class Scoreboard
    # Builds normalized location data from roster and tournament-results fields.
    class LocationBuilder
      def self.build(aggregate:, roster_member:)
        country = normalize_country_object(roster_member&.dig(:country) || aggregate[:countries]&.first)
        raw_affiliation = roster_member&.dig(:affiliation) || aggregate[:affiliation]
        location_source = roster_location_source(roster_member, raw_affiliation)
        parsed_affiliation = AffiliationParser.parse(location_source, country: country)
        city = parsed_affiliation&.kind == :country ? nil : parsed_affiliation&.city || roster_member&.dig(:city)
        state = parsed_affiliation&.kind == :country ? nil : parsed_affiliation&.state || roster_member&.dig(:state)

        {
          raw: raw_affiliation,
          city: city,
          state: state,
          state_name: parsed_affiliation&.state_name,
          country: country,
          kind: normalize_location_kind(parsed_affiliation, country),
          us: parsed_affiliation&.us?,
        }
      end

      def self.normalize_country_object(value)
        case value
        when nil
          nil
        when Array
          normalize_country_object(value.first)
        when Hash
          normalized = ValueNormalizer.normalize_hash(value)
          country = {
            name: ValueNormalizer.normalize_text(normalized[:name] || normalized["name"]),
            ioc: ValueNormalizer.normalize_blank(normalized[:ioc] || normalized["ioc"]),
            alpha2: ValueNormalizer.normalize_blank(country_code(normalized, "alpha_2", "alpha2")),
            alpha3: ValueNormalizer.normalize_blank(country_code(normalized, "alpha_3", "alpha3")),
          }
          country.values.compact.empty? ? nil : country
        else
          value.respond_to?(:to_h) ? normalize_country_object(value.to_h) : nil
        end
      end

      def self.country_code(normalized, underscored_key, compact_key)
        normalized[underscored_key] ||
          normalized[underscored_key.to_sym] ||
          normalized[compact_key] ||
          normalized[compact_key.to_sym]
      end

      def self.roster_location_source(roster_member, fallback_affiliation)
        city = roster_member&.dig(:city)
        state = roster_member&.dig(:state)

        if city && state
          "#{city}, #{state}"
        elsif city
          city
        else
          fallback_affiliation
        end
      end

      def self.normalize_location_kind(parsed_affiliation, country)
        case parsed_affiliation&.kind
        when :city_state
          SchemaValues::LocationKind::CITY_STATE
        when :country
          SchemaValues::LocationKind::COUNTRY
        when :freeform
          SchemaValues::LocationKind::FREEFORM
        else
          country ? SchemaValues::LocationKind::COUNTRY : SchemaValues::LocationKind::UNKNOWN
        end
      end
    end
  end
end
