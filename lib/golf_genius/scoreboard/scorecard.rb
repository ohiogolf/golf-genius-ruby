# frozen_string_literal: true

module GolfGenius
  class Scoreboard
    # Wraps a scorecard hash to provide method-based access to hole-by-hole scoring data.
    #
    # A Scorecard represents a player's detailed scoring information for a specific
    # round, including hole-by-hole scores, to-par values, completion status, and
    # totals for front nine, back nine, and overall.
    #
    # @example Accessing scorecard data
    #   scorecard = row.scorecard(round_id)
    #   scorecard.score          # => "72"
    #   scorecard.status         # => "complete"
    #   scorecard.thru           # => "18"
    #   scorecard.gross_scores   # => [4, 5, 3, 4, 2, 3, 3, 2, 4, ...]
    #   scorecard.to_par_gross   # => [-1, 0, -1, 0, -2, -1, -1, -2, -1, ...]
    #   scorecard.totals         # => { out: 36, in: 36, total: 72 }
    #
    # @example Checking scorecard status
    #   scorecard.thru           # => "8"
    #   scorecard.playing?       # => true
    #   scorecard.finished?      # => false
    #   scorecard.not_started?   # => false
    #
    # @example Iterating through all scorecards for a row
    #   row.scorecards.each do |scorecard|
    #     puts "Score: #{scorecard.score}, Status: #{scorecard.status}"
    #   end
    #
    class Scorecard
      # @return [Hash] the raw scorecard data hash
      attr_reader :data

      # Creates a new Scorecard instance.
      #
      # @param data [Hash] the scorecard data hash
      #
      def initialize(data)
        @data = data
        @card = data[:scorecard] || {}
      end

      # Returns the number of holes completed.
      #
      # @return [String, Integer] holes completed (e.g., "18", "8")
      #
      def thru
        @card[:thru] || @data[:thru]
      end

      # Returns the current score.
      #
      # @return [String, Integer] the score (e.g., "72", "E", "+2")
      #
      def score
        @card[:score] || @data[:score]
      end

      # Returns the completion status.
      #
      # @return [String] status ("complete", "partial", "pending", etc.)
      #
      def status
        @card[:status] || @data[:status]
      end

      # Returns the hole-by-hole gross scores.
      #
      # Array indices correspond to hole numbers (0 = hole 1, 1 = hole 2, etc.).
      # Unplayed holes are represented as nil.
      #
      # @return [Array<Integer, nil>] array of gross scores
      #
      # @example
      #   scorecard.gross_scores  # => [4, 5, 3, 4, 2, 3, 3, 2, 4, 5, 4, 3, 5, 4, 3, 4, 3, 4]
      #
      def gross_scores
        value = @card[:gross_scores] || @data[:gross_scores]
        value.is_a?(Array) ? value : []
      end

      # Returns the hole-by-hole net scores.
      #
      # Array indices correspond to hole numbers (0 = hole 1, 1 = hole 2, etc.).
      # Unplayed holes are represented as nil.
      #
      # @return [Array<Integer, nil>] array of net scores
      #
      def net_scores
        value = @card[:net_scores] || @data[:net_scores]
        value.is_a?(Array) ? value : []
      end

      # Returns the hole-by-hole to-par values for gross scores.
      #
      # Array indices correspond to hole numbers (0 = hole 1, 1 = hole 2, etc.).
      # Values are relative to par (e.g., -1 = birdie, 0 = par, +1 = bogey).
      #
      # @return [Array<Integer, nil>] array of to-par values
      #
      # @example
      #   scorecard.to_par_gross  # => [-1, 0, -1, 0, -2, -1, -1, -2, -1, ...]
      #
      def to_par_gross
        value = @card[:to_par_gross] || @data[:to_par_gross]
        value.is_a?(Array) ? value : []
      end

      # Returns the hole-by-hole to-par values for net scores.
      #
      # Array indices correspond to hole numbers (0 = hole 1, 1 = hole 2, etc.).
      # Values are relative to par (e.g., -1 = birdie, 0 = par, +1 = bogey).
      #
      # @return [Array<Integer, nil>] array of to-par values
      #
      def to_par_net
        value = @card[:to_par_net] || @data[:to_par_net]
        value.is_a?(Array) ? value : []
      end

      # Returns the totals for front nine, back nine, and overall.
      #
      # @return [Hash] hash with :out (front 9), :in (back 9), :total keys
      #
      # @example
      #   scorecard.totals  # => { out: 36, in: 36, total: 72 }
      #
      def totals
        @card[:totals] || @data[:totals] || {}
      end

      # Returns the total to-par for this round.
      #
      # Sums the hole-by-hole to_par_gross values, skipping nil entries
      # (unplayed holes in an in-progress round).
      #
      # @return [Integer, nil] total to-par (e.g., -2, 0, 5) or nil if no data
      #
      # @example
      #   scorecard.to_par_gross  # => [-1, 0, 1, -1, 0, 0, -1, 0, 0, ...]
      #   scorecard.total_to_par  # => -2
      #
      def total_to_par
        values = to_par_gross.compact
        return nil if values.empty?

        values.sum
      end

      # Returns whether the player is currently playing this round.
      #
      # A player is playing if they have a numeric thru value (started but
      # not finished). A numeric thru alone isn't sufficient — WD players
      # have numeric thru from partial play but the round is finished.
      #
      # @return [Boolean] true if playing, false otherwise
      #
      # @example
      #   scorecard.thru      # => "8"
      #   scorecard.playing?  # => true
      #
      #   scorecard.thru      # => "F"
      #   scorecard.playing?  # => false
      #
      #   # WD player who played 6 holes
      #   scorecard.thru      # => "6"
      #   scorecard.finished? # => true (status: complete)
      #   scorecard.playing?  # => false
      #
      def playing?
        thru_value = thru.to_s.strip
        return false if thru_value.empty?
        return false if thru_value == "F"
        return false unless thru_value.match?(/^\d+$/)

        !finished?
      end

      # Returns whether the player has finished this round.
      #
      # A player has finished if thru is "F" (finished) or the scorecard
      # status indicates completion.
      #
      # @return [Boolean] true if finished, false otherwise
      #
      # @example
      #   scorecard.thru       # => "F"
      #   scorecard.finished?  # => true
      #
      #   scorecard.thru       # => "8"
      #   scorecard.finished?  # => false
      #
      def finished?
        thru_value = thru.to_s.strip
        return true if thru_value == "F"

        # Also consider completed/verified status
        status_value = status.to_s.downcase
        return true if %w[completed verified complete].include?(status_value)

        # Historical rounds have score data but no thru/status metadata.
        # If we have a real score, the round is finished.
        thru_value.empty? && round_has_score_data?
      end

      # Returns whether the player has not started this round.
      #
      # A player has not started if thru is empty or nil, or if the
      # scorecard status indicates no holes played.
      #
      # @return [Boolean] true if not started, false otherwise
      #
      # @example
      #   scorecard.thru          # => ""
      #   scorecard.not_started?  # => true
      #
      #   scorecard.thru          # => "8"
      #   scorecard.not_started?  # => false
      #
      def not_started?
        thru_value = thru.to_s.strip

        # Historical rounds have score data but no thru/status metadata.
        # They are not "not started" — the player completed them.
        return false if thru_value.empty? && round_has_score_data?

        return true if thru_value.empty?

        # Check for "no_holes" status
        status_value = status.to_s.downcase
        status_value == "no_holes"
      end

      # Hash-like access to scorecard data.
      #
      # Provides backwards-compatible hash access for internal use
      # (e.g., in cell_value_for method).
      #
      # @param key [Symbol, String] the attribute key
      # @return [Object, nil] the attribute value
      #
      def [](key)
        @data[key.to_sym]
      end

      # Returns the raw scorecard data as a hash.
      #
      # @return [Hash] the underlying data hash
      #
      def to_h
        @data
      end

      private

      # Checks if the round has actual score data.
      #
      # Used to distinguish historical rounds (which have scores but no
      # thru/status metadata) from truly unplayed rounds.
      #
      # @return [Boolean] true if round has meaningful score data
      #
      def round_has_score_data?
        total = @data[:total]
        total && !total.to_s.strip.empty?
      end
    end
  end
end
