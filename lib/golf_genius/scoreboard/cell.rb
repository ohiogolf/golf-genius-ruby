# frozen_string_literal: true

module GolfGenius
  class Scoreboard
    # Wraps a cell value with its column metadata.
    #
    # A Cell represents a single value in the tournament results table, paired
    # with the column it belongs to. This allows iteration over cells while
    # maintaining context about which column each value belongs to.
    #
    # @example Accessing cell data
    #   row.cells.each do |cell|
    #     puts "#{cell.column.label}: #{cell.value}"
    #     puts "Round: #{cell.column.round_name}" if cell.column.round_id
    #   end
    #
    # @example Using type information
    #   row.cells.each do |cell|
    #     case cell.type
    #     when :position
    #       # Format position (handle T2, CUT, etc.)
    #     when :to_par
    #       # Format with +/- and color
    #     when :strokes
    #       # Display as plain number
    #     end
    #   end
    #
    class Cell
      # @return [Object] the cell value (String, Integer, nil, etc.)
      attr_reader :value

      # @return [Column] the column this cell belongs to
      attr_reader :column

      # @return [Integer, nil] the score's relationship to par (e.g., -2, 0, 5)
      attr_reader :to_par

      # Creates a new Cell instance.
      #
      # @param value [Object] the cell value
      # @param column [Column] the column object
      # @param to_par [Integer, nil] the score relative to par
      #
      def initialize(value, column, to_par: nil)
        @value = value
        @column = column
        @to_par = to_par
      end

      # Returns whether this cell contains an actual numeric score.
      # A cell is scored if its value is a number (e.g., "68", "+2", "-3")
      # rather than a status string (e.g., "WD", "DQ", "CUT", "DNS").
      #
      # @return [Boolean] true if the value represents a numeric score
      #
      # @example
      #   cell.value  # => "68"
      #   cell.scored? # => true
      #
      #   cell.value  # => "WD"
      #   cell.scored? # => false
      #
      def scored?
        value.to_s.strip.match?(/\A[+-]?\d+\z/)
      end

      # Returns whether this cell contains a non-scoring status value.
      # Non-scoring values indicate a player didn't complete the tournament
      # normally (e.g., "WD", "DQ", "CUT", "NS", "NC", "MC").
      #
      # Uses the same values as Row::ELIMINATED_POSITIONS.
      #
      # @return [Boolean] true if the value is a non-scoring status
      #
      # @example
      #   cell.value  # => "WD"
      #   cell.non_scoring? # => true
      #
      #   cell.value  # => "68"
      #   cell.non_scoring? # => false
      #
      def non_scoring?
        Row::ELIMINATED_POSITIONS.include?(value.to_s.upcase.strip)
      end

      # Returns the formatted display value for this cell.
      # For to-par columns with valid data, formats consistently:
      # - 0 becomes "E"
      # - Positive values get "+" prefix (e.g., "+5")
      # - Negative values keep "-" prefix (e.g., "-3")
      #
      # For all other cells (strokes, player names, statuses, etc.),
      # returns the raw value unchanged.
      #
      # @return [String, nil] the formatted display value
      #
      # @example
      #   # To-par column
      #   cell.value # => "0"
      #   cell.to_par # => 0
      #   cell.display_value # => "E"
      #
      #   # Strokes column
      #   cell.value # => "68"
      #   cell.display_value # => "68"
      #
      #   # Status value
      #   cell.value # => "WD"
      #   cell.display_value # => "WD"
      #
      def display_value
        # Only format numeric scores in to-par columns
        if scored? && to_par? && !to_par.nil?
          return "E" if to_par.zero?

          return to_par.positive? ? "+#{to_par}" : to_par.to_s
        end

        # For everything else (statuses, "E", strokes, player names, etc.), return raw value
        value
      end

      # Returns whether this score is under par.
      #
      # @return [Boolean] true if to_par is negative
      #
      def under_par?
        to_par&.negative? || false
      end

      # Returns whether this score is over par.
      #
      # @return [Boolean] true if to_par is positive
      #
      def over_par?
        return false if to_par.nil?

        to_par.positive?
      end

      # Returns whether this score is exactly even par.
      #
      # @return [Boolean] true if to_par is zero
      #
      def even_par?
        to_par&.zero? || false
      end

      # Returns the column type (delegates to column).
      #
      # @return [Symbol] the column type (:position, :player, :to_par, :strokes, :thru, :other)
      #
      # @example
      #   cell.type  # => :position
      #
      def type
        column.type
      end

      # Returns whether this is a summary column cell (delegates to column).
      #
      # @return [Boolean] true if this is a summary column
      #
      def summary?
        column.summary?
      end

      # Returns whether this is a round column cell (delegates to column).
      #
      # @return [Boolean] true if this is a round column
      #
      def round?
        column.round?
      end

      # Returns whether this is a position column cell (delegates to column).
      #
      # @return [Boolean] true if column type is :position
      #
      def position?
        column.position?
      end

      # Returns whether this is a player column cell (delegates to column).
      #
      # @return [Boolean] true if column type is :player
      #
      def player?
        column.player?
      end

      # Returns whether this is a to-par column cell (delegates to column).
      #
      # @return [Boolean] true if column type is :to_par
      #
      def to_par?
        column.to_par?
      end

      # Returns whether this is a strokes column cell (delegates to column).
      #
      # @return [Boolean] true if column type is :strokes
      #
      def strokes?
        column.strokes?
      end

      # Returns whether this is a thru column cell (delegates to column).
      #
      # @return [Boolean] true if column type is :thru
      #
      def thru?
        column.thru?
      end

      # Returns the string representation of the cell value.
      #
      # @return [String] the value as a string
      #
      def to_s
        value.to_s
      end

      # Returns the cell as a hash with value and column data.
      #
      # @return [Hash] hash with :value and :column keys
      #
      def to_h
        {
          value: @value,
          column: @column.to_h,
        }
      end
    end
  end
end
