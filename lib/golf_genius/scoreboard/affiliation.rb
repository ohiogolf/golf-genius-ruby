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
    # State data is normalized using USStates, so both abbreviations (OH) and
    # full names (Ohio) are recognized and standardized.
    #
    # @example City with state abbreviation
    #   affiliation = Affiliation.new(city: "Columbus", state: State.new(code: "OH", name: "Ohio"))
    #   affiliation.city        # => "Columbus"
    #   affiliation.state       # => "OH"
    #   affiliation.state_name  # => "Ohio"
    #
    # @example City with full state name
    #   affiliation = Affiliation.new(
    #     city: "Louisville",
    #     state: State.new(code: "KY", name: "Kentucky")
    #   )
    #   affiliation.state       # => "KY"
    #   affiliation.state_name  # => "Kentucky"
    #
    # @example Club name
    #   affiliation = Affiliation.new(city: "Scioto CC")
    #   affiliation.city        # => "Scioto CC"
    #   affiliation.state       # => nil
    #   affiliation.state_name  # => nil
    #
    class Affiliation
      State = Struct.new(:code, :name, keyword_init: true)
      Country = Struct.new(:name, :alpha2, :alpha3, keyword_init: true)

      # @return [String] the city or club name
      attr_reader :city

      # @return [Symbol, nil] the parsed affiliation kind
      attr_reader :kind

      # Creates a new Affiliation instance.
      #
      # @param city [String] the parsed city or club name
      # @param state [State, nil] normalized state metadata
      # @param country [Country, nil] normalized country metadata
      # @param kind [Symbol, nil] the parsed affiliation kind
      #
      def initialize(city:, state: nil, country: nil, kind: nil)
        @city = city
        @state_data = state
        @country_data = country
        @kind = kind
      end

      def state
        @state_data&.code
      end

      # Returns the full state name (e.g., "Ohio"), or nil if not present.
      #
      # @return [String, nil] the state name
      #
      def state_name
        @state_data&.name
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
