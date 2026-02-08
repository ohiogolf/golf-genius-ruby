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
      # @return [Affiliation, nil] parsed Affiliation object or nil if affiliation is blank
      #
      def self.parse(affiliation)
        return nil if affiliation.nil? || affiliation.to_s.strip.empty?

        affiliation = affiliation.strip

        # Check if affiliation contains a comma (city, state format)
        if affiliation.include?(",")
          parts = affiliation.split(",").map(&:strip)
          city = parts[0]
          state_input = parts[1]

          # Find and normalize the state
          state_data = USStates.find(state_input)

          if state_data
            Affiliation.new(
              raw: affiliation,
              city: city,
              state_code: state_data[:code],
              state_name: state_data[:name]
            )
          else
            # State not recognized, store raw input
            Affiliation.new(
              raw: affiliation,
              city: city,
              state_code: state_input,
              state_name: nil
            )
          end
        else
          # No comma: treat entire string as city/club name
          Affiliation.new(
            raw: affiliation,
            city: affiliation,
            state_code: nil,
            state_name: nil
          )
        end
      end
    end
  end
end
