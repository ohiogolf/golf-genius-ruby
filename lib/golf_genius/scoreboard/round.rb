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
      FINISHED_STATUSES = %w[completed verified complete].freeze

      def self.extract_number(name)
        match = name.to_s.match(/\d+/)
        match ? match[0].to_i : nil
      end

      def self.canonical_name(name, index = nil)
        round_number = extract_number(name) || index
        return name unless round_number

        "R#{round_number}"
      end

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
        value(:id)
      end

      # Returns the round name.
      #
      # @return [String] the round name (e.g., "R1", "R2", "R3")
      #
      def name
        value(:name)
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
        self.class.extract_number(name)
      end

      # Returns the round date.
      #
      # The date is automatically parsed from a string (e.g., "2026-03-15") to
      # a Date object. If parsing fails, the original string is returned.
      #
      # @return [Date, String] the round date as a Date object or original string
      #
      def date
        value(:date)
      end

      def index
        value(:index)
      end

      # Returns the raw in_progress value.
      #
      # @return [Boolean, nil] true if in progress, false/nil otherwise
      #
      def in_progress
        value(:in_progress)
      end

      # Returns the raw status value when available.
      #
      # @return [String, nil] round status from event metadata
      #
      def status
        value(:status)
      end

      # Returns whether the round has explicit status metadata.
      #
      # @return [Boolean] true if status is present
      #
      def explicit_status?
        status.to_s.strip != ""
      end

      # Returns whether the round has not started yet.
      #
      # @return [Boolean] true if unstarted, false otherwise
      #
      def unstarted?
        return status.to_s == "not started" if explicit_status?

        future?
      end

      # Returns whether the round is currently being played.
      #
      # @return [Boolean] true if playing, false otherwise
      #
      def playing?
        return status.to_s == "in progress" if explicit_status?

        !!in_progress
      end

      # Returns whether the round is scheduled for a future date.
      #
      # @return [Boolean] true when the round date is after today
      #
      def future?
        comparison_date = case date
                          when Date
                            date
                          else
                            date.to_date if date.respond_to?(:to_date)
                          end

        comparison_date && comparison_date > Date.today
      end

      # Returns whether the round is complete.
      #
      # Future rounds are not complete, even though they are also not
      # in progress. For same-day rounds without explicit status metadata,
      # callers should use scorecard/row state for stricter readiness checks.
      #
      # @return [Boolean] true if complete, false if still playing
      #
      def complete?
        return status.to_s == "completed" if explicit_status?
        return false if playing?
        return false if future?
        return false if date.is_a?(Date) && date == Date.today

        true
      end

      # Returns whether the round has started.
      #
      # @return [Boolean] true if the round is either playing or complete
      #
      def started?
        playing? || complete?
      end

      # Returns the raw round data as a hash.
      #
      # @return [Hash] the underlying data hash
      #
      def to_h
        @data
      end

      private

      def value(key)
        return @data[key] if @data.key?(key)
        return @data[key.to_s] if @data.key?(key.to_s)

        nil
      end

      def write_value(key, new_value)
        target_key = @data.key?(key.to_s) && !@data.key?(key) ? key.to_s : key
        @data[target_key] = new_value
      end

      # Parses the date string to a Date object.
      # If parsing fails, keeps the original string value.
      #
      # @return [void]
      #
      def parse_date!
        value = self.value(:date)
        return unless value.is_a?(String) && !value.strip.empty?

        write_value(:date, Date.parse(value))
      rescue ArgumentError
        # Keep as string if parsing fails
        write_value(:date, value)
      end
    end
  end
end
