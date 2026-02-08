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
      # @return [String] the raw affiliation string
      attr_reader :raw

      # @return [String] the city or club name
      attr_reader :city

      # @return [String, nil] the state abbreviation (e.g., "OH"), or nil if not present
      attr_reader :state_code

      # @return [String, nil] the full state name (e.g., "Ohio"), or nil if not present
      attr_reader :state_name

      # Creates a new Affiliation instance.
      #
      # @param raw [String] the raw affiliation string
      # @param city [String] the parsed city or club name
      # @param state_code [String, nil] the normalized state abbreviation
      # @param state_name [String, nil] the full state name
      #
      def initialize(raw:, city:, state_code: nil, state_name: nil)
        @raw = raw
        @city = city
        @state_code = state_code
        @state_name = state_name
      end

      # Returns the state abbreviation (alias for state_code).
      #
      # @return [String, nil] the state abbreviation, or nil if not present
      #
      def state
        state_code
      end

      # Returns the full affiliation string (alias for raw).
      #
      # @return [String] the full affiliation string
      #
      def full
        raw
      end

      # Returns whether the affiliation includes a state.
      #
      # @return [Boolean] true if state is present, false otherwise
      #
      def state?
        !state.nil?
      end
    end
  end
end
