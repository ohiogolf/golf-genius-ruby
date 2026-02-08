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
    #   name.full_name   # => "John Doe"
    #
    # @example Name with suffix
    #   name = Name.new(first_name: "Paul", last_name: "Schlimm", suffix: "Jr.")
    #   name.full_name   # => "Paul Schlimm Jr."
    #
    # @example Name with metadata
    #   name = Name.new(first_name: "Adam", last_name: "Black", metadata: ["(a)"])
    #   name.full_name   # => "Adam Black (a)"
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

      # @return [Affiliation, nil] the player's affiliation
      attr_reader :affiliation

      # Creates a new Name instance.
      #
      # @param first_name [String] the first name
      # @param last_name [String] the last name
      # @param suffix [String, nil] optional generational suffix
      # @param metadata [Array<String>] optional metadata annotations
      # @param affiliation [Affiliation, nil] optional player affiliation
      #
      def initialize(first_name:, last_name:, suffix: nil, metadata: [], affiliation: nil)
        @first_name = first_name
        @last_name = last_name
        @suffix = suffix
        @metadata = Array(metadata)
        @affiliation = affiliation
      end

      # Returns the full name with all components.
      #
      # Combines first name, last name, suffix, and metadata into a single string.
      #
      # @return [String] the full name
      #
      # @example
      #   Name.new(first_name: "Robert", last_name: "Gerwin", suffix: "II", metadata: ["(a)"]).full_name
      #   # => "Robert Gerwin II (a)"
      #
      def full_name
        parts = [first_name, last_name].reject(&:empty?)
        parts << suffix if suffix
        name = parts.join(" ")
        name = "#{name} #{metadata.join(" ")}" if metadata.any?
        name
      end

      # Returns whether this player has the amateur indicator.
      #
      # @return [Boolean] true if metadata includes "(a)"
      #
      def amateur?
        metadata.include?("(a)")
      end

      # Returns a hash representation of the name.
      #
      # @return [Hash] hash with first_name, last_name, suffix, metadata keys
      #
      def to_h
        {
          first_name: first_name,
          last_name: last_name,
          suffix: suffix,
          metadata: metadata,
        }
      end

      # Returns the string representation (full name).
      #
      # @return [String] the full name
      #
      def to_s
        full_name
      end
    end
  end
end
