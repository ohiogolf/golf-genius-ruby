# frozen_string_literal: true

module GolfGenius
  class Scoreboard
    # Represents a parsed player name with its components.
    #
    # A Name holds the parsed components of a player's name, including
    # first name, last name, optional suffix (Jr., Sr., II, etc.), and
    # metadata like amateur indicators.
    #
    # @example Simple name
    #   name = Name.new(first_name: "John", last_name: "Doe")
    #   name.first_name  # => "John"
    #   name.last_name   # => "Doe"
    #   name.amateur?    # => false
    #
    # @example Name with metadata
    #   name = Name.new(first_name: "Adam", last_name: "Black", metadata: ["(a)"])
    #   name.amateur?    # => true
    #
    class Name
      # @return [String] the first name
      attr_reader :first_name

      # @return [String] the last name (without suffix)
      attr_reader :last_name

      # @return [String, nil] the generational suffix (Jr., Sr., II, III, IV)
      attr_reader :suffix

      # @return [Array<String>] metadata annotations like "(a)" for amateur
      attr_reader :metadata

      # Creates a new Name instance.
      #
      # @param first_name [String] the first name
      # @param last_name [String] the last name
      # @param suffix [String, nil] optional generational suffix
      # @param metadata [Array<String>] optional metadata annotations
      #
      def initialize(first_name:, last_name:, suffix: nil, metadata: [])
        @first_name = first_name
        @last_name = last_name
        @suffix = suffix
        @metadata = Array(metadata)
      end

      # Returns whether this player has the amateur indicator.
      #
      # @return [Boolean] true if metadata includes "(a)"
      #
      def amateur?
        metadata.include?("(a)")
      end
    end
  end
end
