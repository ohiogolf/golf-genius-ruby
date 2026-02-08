# frozen_string_literal: true

require "date"

module GolfGenius
  class Scoreboard
    # Wraps a round hash to provide method-based access to round metadata.
    #
    # A Round represents a single round of golf within a tournament, including
    # its date, name, and completion status. The date field is automatically
    # parsed from a string to a Date object for easier manipulation.
    #
    # @example Accessing round data
    #   round.id           # => 1615930
    #   round.name         # => "R1"
    #   round.date         # => #<Date: 2026-03-15>
    #   round.playing?     # => false
    #   round.complete?    # => true
    #
    class Round
      # @return [Hash] the raw round data hash
      attr_reader :data

      # Creates a new Round instance.
      #
      # @param data [Hash] the round data hash
      #
      def initialize(data)
        @data = data
        parse_date!
      end

      # Returns the round ID.
      #
      # @return [Integer] the round ID
      #
      def id
        @data[:id]
      end

      # Returns the round name.
      #
      # @return [String] the round name (e.g., "R1", "R2", "R3")
      #
      def name
        @data[:name]
      end

      # Returns the round number extracted from the name.
      #
      # Parses the numeric portion from round names like "R1", "R2", "Round 3", etc.
      # Returns nil if no number can be extracted.
      #
      # @return [Integer, nil] the round number (1, 2, 3, 4, etc.) or nil
      #
      # @example
      #   round.name    # => "R1"
      #   round.number  # => 1
      #
      #   round.name    # => "Round 3"
      #   round.number  # => 3
      #
      def number
        return nil unless name

        # Extract first number from name (handles "R1", "Round 2", etc.)
        match = name.to_s.match(/\d+/)
        match ? match[0].to_i : nil
      end

      # Returns the round date.
      #
      # The date is automatically parsed from a string (e.g., "2026-03-15") to
      # a Date object. If parsing fails, the original string is returned.
      #
      # @return [Date, String] the round date as a Date object or original string
      #
      def date
        @data[:date]
      end

      # Returns the raw in_progress value.
      #
      # @return [Boolean, nil] true if in progress, false/nil otherwise
      #
      def in_progress
        @data[:in_progress]
      end

      # Returns whether the round is currently being played.
      #
      # @return [Boolean] true if playing, false otherwise
      #
      def playing?
        !!@data[:in_progress]
      end

      # Returns whether the round is complete.
      #
      # This is the inverse of {#playing?}.
      #
      # @return [Boolean] true if complete, false if still playing
      #
      def complete?
        !playing?
      end

      # Returns the raw round data as a hash.
      #
      # @return [Hash] the underlying data hash
      #
      def to_h
        @data
      end

      private

      # Parses the date string to a Date object.
      # If parsing fails, keeps the original string value.
      #
      # @return [void]
      #
      def parse_date!
        value = @data[:date]
        return unless value.is_a?(String) && !value.strip.empty?

        @data[:date] = Date.parse(value)
      rescue ArgumentError
        # Keep as string if parsing fails
        @data[:date] = value
      end
    end
  end
end
