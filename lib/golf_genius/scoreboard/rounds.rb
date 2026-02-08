# frozen_string_literal: true

require_relative "round"

module GolfGenius
  class Scoreboard
    # Collection wrapper for tournament rounds.
    #
    # Provides convenient access to round data and metadata like finding
    # the currently in-progress round.
    #
    # @example Accessing rounds
    #   rounds = tournament.rounds
    #   rounds.size          # => 4
    #   rounds.first         # => #<Round id=101, name="R1">
    #   rounds.last          # => #<Round id=104, name="R4">
    #   rounds.current       # => #<Round id=102, name="R2", playing?=true>
    #   rounds[2]            # => #<Round id=103, name="R3">
    #   rounds.each { |r| puts r.name }
    #   rounds.to_h          # => [{id: 101, ...}, {id: 102, ...}]
    #
    class Rounds
      include Enumerable

      # Creates a new Rounds collection.
      #
      # @param rounds_data [Array<Hash>] array of round data hashes
      #
      def initialize(rounds_data)
        @rounds = rounds_data.map { |round| Round.new(round) }
      end

      # Returns the round currently in progress.
      #
      # Finds the first round where playing? is true. Returns nil if no
      # round is currently being played.
      #
      # @return [Round, nil] the in-progress round or nil
      #
      # @example
      #   rounds.current  # => #<Round id=102, name="R2", playing?=true>
      #
      def current
        @rounds.find(&:playing?)
      end

      # Returns the number of rounds.
      #
      # @return [Integer] the round count
      #
      def size
        @rounds.size
      end

      # Returns all rounds as an array of hashes.
      #
      # @return [Array<Hash>] array of round hashes
      #
      def to_h
        @rounds.map(&:to_h)
      end

      # Iterates over each round.
      #
      # @yield [Round] each round in the collection
      # @return [Enumerator] if no block given
      #
      def each(&block)
        @rounds.each(&block)
      end

      # Returns the round at the given index.
      #
      # @param index [Integer] the array index
      # @return [Round, nil] the round at index or nil
      #
      def [](index)
        @rounds[index]
      end

      # Returns the first round.
      #
      # Note: Although Enumerable provides a #first method, we override it here
      # for better performance (direct array access vs iteration).
      #
      # @return [Round, nil] the first round or nil if no rounds
      #
      # @example
      #   rounds.first  # => #<Round id=101, name="R1">
      #
      def first
        @rounds.first
      end

      # Returns the last round.
      #
      # Note: Enumerable does not provide a #last method, so we implement it
      # here for convenient access to the final round.
      #
      # @return [Round, nil] the last round or nil if no rounds
      #
      # @example
      #   rounds.last  # => #<Round id=104, name="R4">
      #
      def last
        @rounds.last
      end
    end
  end
end
