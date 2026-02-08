# frozen_string_literal: true

require_relative "cell"
require_relative "column"
require_relative "row"
require_relative "round"
require_relative "rounds"
require_relative "scorecard"

module GolfGenius
  class Scoreboard
    # Wraps a tournament hash to provide method-based access.
    #
    # A Tournament represents a single tournament within an event/round, including
    # its metadata (name, cut text, adjusted status), rounds, columns, and player rows.
    #
    # @example Accessing tournament data
    #   tournament = scoreboard.tournaments.first
    #   tournament.id           # => 4522280
    #   tournament.name         # => "Championship Flight"
    #   tournament.adjusted?    # => false
    #   tournament.rounds       # => [#<Round...>, #<Round...>]
    #   tournament.columns      # => [#<Column...>, #<Column...>]
    #   tournament.rows         # => [#<Row...>, #<Row...>]
    #
    class Tournament
      # @return [Hash] the raw tournament data hash
      attr_reader :data

      # Creates a new Tournament instance.
      #
      # @param data [Hash] the tournament data hash
      #
      def initialize(data)
        @data = data
      end

      # Returns the tournament ID.
      #
      # @return [Integer] the tournament ID
      #
      def id
        @data[:meta][:tournament_id]
      end

      alias tournament_id id

      # Returns the tournament name.
      #
      # @return [String] the tournament name (e.g., "Championship Flight")
      #
      def name
        @data[:meta][:name]
      end

      # Returns the cut text for players who didn't make the cut.
      #
      # @return [String, nil] cut text or nil if no cut
      #
      def cut_text
        @data[:meta][:cut_text]
      end

      # Returns whether the tournament has adjusted scores.
      #
      # @return [Boolean] true if adjusted, false otherwise
      #
      def adjusted?
        @data[:meta][:adjusted]
      end

      # Returns all rounds for this tournament as a Rounds collection.
      #
      # The Rounds collection provides access to round metadata and supports
      # iteration. Use +to_h+ to convert all Round objects to hashes for
      # serialization.
      #
      # @return [Rounds] collection of Round objects
      #
      # @example
      #   tournament.rounds.each do |round|
      #     puts "#{round.name}: #{round.date}"
      #   end
      #   tournament.rounds.current  # => #<Round id=102, name="R2", ...>
      #   tournament.rounds.size     # => 4
      #   tournament.rounds.to_h     # => [{id: 1, name: "R1", ...}, ...]
      #
      def rounds
        @rounds ||= Rounds.new(@data[:meta][:rounds])
      end

      # Returns all columns for this tournament as Column objects.
      #
      # Combines summary columns (position, name, total, etc.) with round-specific
      # columns (R1, R2, etc.) in display order. The returned array has a custom
      # +to_h+ method for serialization.
      #
      # @return [Array<Column>] flat array of Column objects
      #
      # @example
      #   tournament.columns.each do |col|
      #     puts "#{col.label} (#{col.format})"
      #   end
      #   tournament.columns.to_h  # => [{key: "pos", label: "Pos", ...}, ...]
      #
      def columns
        @columns ||= begin
          summary_cols = @data[:columns][:summary].map { |col| Column.new(col) }
          round_cols = @data[:columns][:rounds].flat_map { |round| round[:columns].map { |col| Column.new(col) } }
          cols = summary_cols + round_cols

          # Add to_h method to convert all Column objects to hashes
          # This allows tournament.columns.to_h to return an array of column hashes
          # for serialization (e.g., to JSON)
          def cols.to_h
            map(&:to_h)
          end

          cols
        end
      end

      # Returns all player/team rows for this tournament as Row objects.
      #
      # @return [Array<Row>] array of Row objects representing players/teams
      #
      # @example
      #   tournament.rows.each do |row|
      #     puts "#{row.name}: #{row.cells.map(&:value).join(', ')}"
      #   end
      #
      def rows
        @rows ||= @data[:rows].map { |row| Row.new(row, self) }
      end

      # Returns the cut line text from the tournament metadata.
      #
      # This text is typically displayed above cut players to explain why they
      # were eliminated. The exact wording comes from Golf Genius and may support
      # internationalization.
      #
      # @return [String, nil] the cut line text or nil if not present
      #
      # @example
      #   tournament.cut_line_text
      #   # => "The following players did not make the cut"
      #
      def cut_line_text
        @data[:meta][:cut_text]
      end

      # Returns whether this tournament has any cut players.
      #
      # Checks if any player has a position indicating they were eliminated
      # (CUT, MC, WD, DQ, NS, NC).
      #
      # @return [Boolean] true if any players were cut/eliminated
      #
      # @example
      #   tournament.cut_players?  # => true
      #
      def cut_players?
        rows.any?(&:eliminated?)
      end

      # Returns a new Tournament with rows sorted by the given criteria.
      #
      # Supports sorting by position (with smart ordering), last_name (alphabetical),
      # or competing (active players first). Returns a new Tournament instance with
      # sorted rows; the original is unchanged.
      #
      # @param keys [Array<Symbol>] sort keys (:position, :last_name, :competing)
      # @param direction [Symbol] sort direction (:asc or :desc)
      # @return [Tournament] new Tournament with sorted rows
      #
      # @example Default sort (competing first, then by position)
      #   sorted = tournament.sort
      #
      # @example Sort by position only
      #   sorted = tournament.sort(:position)
      #
      # @example Sort alphabetically by last name
      #   alpha = tournament.sort(:last_name)
      #
      # @example Competing players first, then alphabetically
      #   sorted = tournament.sort(:competing, :last_name)
      #
      # @example Multi-key sort (position, then last name for ties)
      #   sorted = tournament.sort(:position, :last_name)
      #
      def sort(*keys, direction: :asc)
        # Default to competing players first, then by position
        keys = %i[competing position] if keys.empty?

        # Sort rows using the comparator
        sorted_rows = rows.sort do |a, b|
          compare_rows(a, b, keys, direction)
        end

        # Build new tournament data with sorted rows
        sorted_data = @data.dup
        sorted_data[:rows] = sorted_rows.map(&:to_h)

        Tournament.new(sorted_data)
      end

      # Returns the raw tournament data as a hash.
      #
      # @return [Hash] the underlying data hash
      #
      def to_h
        @data
      end

      private

      # Compares two rows based on sort keys and direction.
      #
      # @param row_a [Row] first row
      # @param row_b [Row] second row
      # @param keys [Array<Symbol>] sort keys
      # @param direction [Symbol] sort direction
      # @return [Integer] comparison result (-1, 0, 1)
      #
      def compare_rows(row_a, row_b, keys, direction)
        keys.each do |key|
          result = case key
                   when :position
                     compare_positions(row_a.position, row_b.position)
                   when :last_name
                     compare_strings(row_a.last_name, row_b.last_name)
                   when :competing
                     compare_competing(row_a, row_b)
                   else
                     raise ArgumentError, "Unknown sort key: #{key}"
                   end

          # Apply direction
          result = -result if direction == :desc

          # Return if not equal (continue to next key if equal)
          return result unless result.zero?
        end

        0 # All keys were equal
      end

      # Compares two position strings with smart ordering.
      #
      # Numeric positions first (1, 2, 3), then tied (T2, T5),
      # then status codes last (CUT, DQ, WD - alphabetical).
      #
      # @param pos_a [String, nil] first position
      # @param pos_b [String, nil] second position
      # @return [Integer] comparison result
      #
      def compare_positions(pos_a, pos_b)
        a_val = position_sort_value(pos_a)
        b_val = position_sort_value(pos_b)

        a_val <=> b_val
      end

      # Converts a position string to a sortable value.
      #
      # Returns an array [priority, value] for comparison.
      # Priority: 1=playing (numeric or tied), 2=eliminated, 3=unknown
      #
      # @param position [String, nil] position string
      # @return [Array] sortable array [priority, value]
      #
      def position_sort_value(position)
        return [3, ""] if position.nil? || position.empty?

        pos = position.to_s.strip.upcase

        # Eliminated positions (using Row constant) sort to end alphabetically
        if Row::CUT_POSITIONS.include?(pos)
          return [2, pos] # Priority 2, alphabetical by code
        end

        # Tied positions: "T2" -> priority 1, numeric 2 (same as non-tied)
        if pos.start_with?("T")
          numeric = pos[1..].to_i
          return [1, numeric] if numeric.positive?
        end

        # Numeric positions: "1", "2", "45" -> priority 1
        numeric = pos.to_i
        return [1, numeric] if numeric.positive?

        # Unknown format - sort to end
        [3, pos]
      end

      # Compares two strings alphabetically (case-insensitive).
      #
      # Nil or empty strings sort to the end.
      #
      # @param str_a [String, nil] first string
      # @param str_b [String, nil] second string
      # @return [Integer] comparison result
      #
      def compare_strings(str_a, str_b)
        # Nil or empty strings sort to end
        a_empty = str_a.nil? || str_a.to_s.strip.empty?
        b_empty = str_b.nil? || str_b.to_s.strip.empty?

        return 0 if a_empty && b_empty
        return 1 if a_empty  # a is nil/empty, b is not -> a comes after
        return -1 if b_empty # b is nil/empty, a is not -> a comes before

        # Both have values, compare normally
        str_a.to_s.downcase <=> str_b.to_s.downcase
      end

      # Compares two rows by competing status.
      #
      # Competing players (not eliminated) sort before eliminated players.
      #
      # @param row_a [Row] first row
      # @param row_b [Row] second row
      # @return [Integer] comparison result
      #
      def compare_competing(row_a, row_b)
        a_competing = !row_a.eliminated?
        b_competing = !row_b.eliminated?

        return 0 if a_competing == b_competing
        return -1 if a_competing # a is competing, b is not -> a comes first

        1 # b is competing, a is not -> b comes first
      end
    end
  end
end
