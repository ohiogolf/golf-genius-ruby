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
