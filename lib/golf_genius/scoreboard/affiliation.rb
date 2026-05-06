# frozen_string_literal: true

module GolfGenius
  class Scoreboard
    # Represents a parsed affiliation (location or club).
    #
    # An affiliation can be:
    # - A city/state combination: "Columbus, OH" or "Columbus, Ohio"
    # - A club name: "Scioto Country Club"
    # - A simple city: "Tampa"
    #
    # State data is normalized using Carmen, so both abbreviations (OH) and
    # full names (Ohio) are recognized and standardized.
    #
    # @example City with state abbreviation
    #   affiliation = Affiliation.new(raw: "Columbus, OH", city: "Columbus", state_code: "OH", state_name: "Ohio")
    #   affiliation.city        # => "Columbus"
    #   affiliation.state       # => "OH"
    #   affiliation.state_code  # => "OH"
    #   affiliation.state_name  # => "Ohio"
    #   affiliation.full        # => "Columbus, OH"
    #
    # @example City with full state name
    #   affiliation = Affiliation.new(
    #     raw: "Louisville, Kentucky",
    #     city: "Louisville",
    #     state_code: "KY",
    #     state_name: "Kentucky"
    #   )
    #   affiliation.state       # => "KY"
    #   affiliation.state_name  # => "Kentucky"
    #
    # @example Club name
    #   affiliation = Affiliation.new(raw: "Scioto CC", city: "Scioto CC", state_code: nil, state_name: nil)
    #   affiliation.city        # => "Scioto CC"
    #   affiliation.state       # => nil
    #   affiliation.state_name  # => nil
    #
    class Affiliation
      State = Struct.new(:code, :name, keyword_init: true)
      Country = Struct.new(:name, :alpha2, :alpha3, keyword_init: true)

      # @return [String] the raw affiliation string
      attr_reader :raw

      # @return [String] the city or club name
      attr_reader :city

      # @return [Symbol, nil] the parsed affiliation kind
      attr_reader :kind

      # Creates a new Affiliation instance.
      #
      # @param raw [String] the raw affiliation string
      # @param city [String] the parsed city or club name
      # @param state [State, nil] normalized state metadata
      # @param country [Country, nil] normalized country metadata
      # @param kind [Symbol, nil] the parsed affiliation kind
      #
      def initialize(raw:, city:, state: nil, country: nil, kind: nil)
        @raw = raw
        @city = city
        @state_data = state
        @country_data = country
        @kind = kind
      end

      # Returns the state abbreviation (alias for state_code).
      #
      # @return [String, nil] the state abbreviation, or nil if not present
      #
      def state
        state_code
      end

      # Returns the state abbreviation (e.g., "OH"), or nil if not present.
      #
      # @return [String, nil] the state abbreviation
      #
      def state_code
        @state_data&.code
      end

      # Returns the full state name (e.g., "Ohio"), or nil if not present.
      #
      # @return [String, nil] the state name
      #
      def state_name
        @state_data&.name
      end

      # Returns the full affiliation string (alias for raw).
      #
      # @return [String] the full affiliation string
      #
      def full
        raw
      end

      # Returns the country name when known.
      #
      # @return [String, nil] the country name
      #
      def country
        @country_data&.name
      end

      # Returns whether the affiliation includes a state.
      #
      # @return [Boolean] true if state is present, false otherwise
      #
      def state?
        !state.nil?
      end

      # Returns whether the affiliation is a country-only location.
      #
      # @return [Boolean] true if country-only, false otherwise
      #
      def country_only?
        kind == :country
      end

      # Returns whether the affiliation is a recognized US city/state location.
      #
      # @return [Boolean] true if city/state, false otherwise
      #
      def city_state?
        kind == :city_state
      end

      # Returns whether the affiliation belongs to the United States.
      #
      # @return [Boolean] true if US, false otherwise
      #
      def us?
        %w[US USA].include?(@country_data&.alpha2) || @country_data&.alpha3 == "USA"
      end
    end
  end
end
