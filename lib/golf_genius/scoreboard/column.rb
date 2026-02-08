# frozen_string_literal: true

module GolfGenius
  class Scoreboard
    # Wraps a column hash to provide method-based access to column metadata.
    #
    # A Column represents a single column in the tournament results table,
    # including its display label, format type, and optionally which round
    # it belongs to.
    #
    # @example Accessing column data
    #   col.label       # => "Pos"
    #   col.format      # => "position"
    #   col.type        # => :position
    #   col.round_id    # => nil (summary column)
    #   col.round_name  # => nil (summary column)
    #
    #   round_col.label      # => "R1"
    #   round_col.type       # => :strokes
    #   round_col.round_id   # => 1615930
    #   round_col.round_name # => "R1"
    #
    class Column
      # Format values indicating position columns
      POSITION_FORMATS = %w[
        position
      ].freeze

      # Format values indicating player name columns
      PLAYER_FORMATS = %w[
        player
      ].freeze

      # Format values indicating thru/holes completed columns
      THRU_FORMATS = %w[
        thru
      ].freeze

      # Format values indicating to-par score columns
      TO_PAR_FORMATS = %w[
        to-par-gross
        to-par-net
        total-to-par-gross
        total-to-par-net
      ].freeze

      # Format values indicating stroke total columns
      STROKES_FORMATS = %w[
        round-total
        total-gross
        total-net
        total
      ].freeze
      # @return [Hash] the raw column data hash
      attr_reader :data

      # Creates a new Column instance.
      #
      # @param data [Hash] the column data hash
      #
      def initialize(data)
        @data = data
      end

      # Returns the column key used for data lookup.
      #
      # @return [Symbol] the column key (e.g., :position, :total, :score)
      #
      def key
        @data[:key]
      end

      # Returns the column format type.
      #
      # @return [String] format type (e.g., "position", "player-name", "round-total")
      #
      def format
        @data[:format]
      end

      # Returns the column display label.
      #
      # @return [String] the label shown in table headers (e.g., "Pos", "Player", "Total")
      #
      def label
        @data[:label]
      end

      # Returns the column index in the table.
      #
      # @return [Integer] zero-based column index
      #
      def index
        @data[:index]
      end

      # Returns the round ID if this is a round-specific column.
      #
      # @return [Integer, nil] round ID or nil for summary columns
      #
      def round_id
        @data[:round_id]
      end

      # Returns the round name if this is a round-specific column.
      #
      # @return [String, nil] round name (e.g., "R1", "R2") or nil for summary columns
      #
      def round_name
        @data[:round_name]
      end

      # Returns the column type based on the format.
      #
      # Identifies the type of data this column contains.
      #
      # @return [Symbol] the column type
      #   - :position - Tournament position (1, 2, T3, CUT, etc.)
      #   - :player - Player name
      #   - :to_par - Score relative to par (+5, -3, E, etc.)
      #   - :strokes - Total strokes (68, 72, etc.)
      #   - :thru - Holes completed (F, 18, 9, etc.)
      #   - :other - Unknown/unrecognized format
      #
      # @example
      #   position_column.type  # => :position
      #   r1_column.type        # => :strokes
      #   to_par_column.type    # => :to_par
      #
      def type
        fmt = format.to_s.downcase

        return :position if POSITION_FORMATS.include?(fmt)
        return :player if PLAYER_FORMATS.include?(fmt)
        return :thru if THRU_FORMATS.include?(fmt)
        return :to_par if TO_PAR_FORMATS.include?(fmt)
        return :strokes if STROKES_FORMATS.include?(fmt)

        # Log unknown formats to help identify missing mappings
        warn "Unknown column format: #{format.inspect}" unless fmt.empty?

        :other
      end

      # Returns whether this is a summary column.
      #
      # Summary columns don't belong to a specific round (e.g., "Pos", "Player", "Total").
      #
      # @return [Boolean] true if this is a summary column
      #
      # @example
      #   position_column.summary?  # => true
      #   r1_column.summary?        # => false
      #
      def summary?
        round_id.nil?
      end

      # Returns whether this is a round-specific column.
      #
      # Round columns belong to a specific round (e.g., "R1", "To Par R2").
      #
      # @return [Boolean] true if this is a round column
      #
      # @example
      #   r1_column.round?          # => true
      #   position_column.round?    # => false
      #
      def round?
        !round_id.nil?
      end

      # Returns whether this is a position column.
      #
      # @return [Boolean] true if type is :position
      #
      # @example
      #   column.position?  # => true
      #
      def position?
        type == :position
      end

      # Returns whether this is a player column.
      #
      # @return [Boolean] true if type is :player
      #
      # @example
      #   column.player?  # => true
      #
      def player?
        type == :player
      end

      # Returns whether this is a to-par column.
      #
      # @return [Boolean] true if type is :to_par
      #
      # @example
      #   column.to_par?  # => true
      #
      def to_par?
        type == :to_par
      end

      # Returns whether this is a strokes column.
      #
      # @return [Boolean] true if type is :strokes
      #
      # @example
      #   column.strokes?  # => true
      #
      def strokes?
        type == :strokes
      end

      # Returns whether this is a thru column.
      #
      # @return [Boolean] true if type is :thru
      #
      # @example
      #   column.thru?  # => true
      #
      def thru?
        type == :thru
      end

      # Returns the raw column data as a hash.
      #
      # @return [Hash] the underlying data hash
      #
      def to_h
        @data
      end
    end
  end
end
