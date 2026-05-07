# frozen_string_literal: true

require_relative "affiliation"
require_relative "us_states"

module GolfGenius
  class Scoreboard
    # Parses affiliation strings into Affiliation objects.
    #
    # Handles various affiliation formats found in Golf Genius data:
    # - City with state: "Columbus, OH", "Louisville, KY", "Columbus, Ohio"
    # - Club names: "Scioto Country Club", "Columbus CC"
    # - Simple cities: "Tampa", "Orlando"
    #
    # State data is normalized to provide both abbreviation and full name.
    # Recognizes both "OH" and "Ohio" as valid inputs.
    #
    # @example Parsing a city with state code
    #   affiliation = AffiliationParser.parse("Columbus, OH")
    #   affiliation.city        # => "Columbus"
    #   affiliation.state       # => "OH"
    #   affiliation.state_name  # => "Ohio"
    #
    # @example Parsing a city with full state name
    #   affiliation = AffiliationParser.parse("Columbus, Ohio")
    #   affiliation.city        # => "Columbus"
    #   affiliation.state       # => "OH"
    #   affiliation.state_name  # => "Ohio"
    #
    # @example Parsing a club name
    #   affiliation = AffiliationParser.parse("Scioto CC")
    #   affiliation.city   # => "Scioto CC"
    #   affiliation.state  # => nil
    #
    module AffiliationParser
      # Parses an affiliation string into an Affiliation object.
      #
      # Normalizes state codes and names using USStates lookup.
      # Recognizes both abbreviations (OH, KY) and full names (Ohio, Kentucky).
      #
      # @param affiliation [String, nil] the affiliation string to parse
      # @param country [Hash, nil] optional country metadata from tournament_results
      # @return [Affiliation, nil] parsed Affiliation object or nil if affiliation is blank
      #
      def self.parse(affiliation, country: nil)
        return nil if affiliation.nil? || affiliation.to_s.strip.empty?

        affiliation = affiliation.strip
        country_data = normalize_country(country)

        # Check if affiliation contains a comma (city, state format)
        if affiliation.include?(",")
          parts = affiliation.split(",").map(&:strip)
          city = parts[0]
          state_input = parts[1]

          # Find and normalize the state
          state_data = USStates.find(state_input)
          state = normalize_state(state_data, fallback_code: state_input)

          build_affiliation(city: city, state: state, country: country_data, kind: :city_state)
        else
          kind = country_match?(affiliation, country_data) ? :country : :freeform

          # No comma: treat entire string as city/club name
          build_affiliation(city: affiliation, state: nil, country: country_data, kind: kind)
        end
      end

      def self.build_affiliation(city:, state:, country:, kind:)
        Affiliation.new(city: city, state: state, country: country, kind: kind)
      end

      def self.normalize_state(state_data, fallback_code: nil)
        if state_data
          Affiliation::State.new(code: state_data[:code], name: state_data[:name])
        elsif fallback_code
          Affiliation::State.new(code: fallback_code, name: nil)
        end
      end

      def self.normalize_country(country)
        return nil unless country.is_a?(Hash)

        normalized = country.transform_keys(&:to_s)

        Affiliation::Country.new(
          name: normalized["name"],
          alpha2: normalized["alpha_2"] || normalized["alpha2"],
          alpha3: normalized["alpha_3"] || normalized["alpha3"]
        )
      end

      def self.country_match?(affiliation, country_data)
        country_name = country_data&.name
        return false if country_name.to_s.strip.empty?

        normalize_label(affiliation) == normalize_label(country_name)
      end

      def self.normalize_label(value)
        value.to_s.downcase.gsub(/[^a-z0-9]+/, " ").strip
      end
    end
  end
end
