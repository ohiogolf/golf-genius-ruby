# frozen_string_literal: true

module GolfGenius
  class Scoreboard
    # Decomposes row cells into summary and round-specific sections.
    #
    # This class is responsible for:
    # - Mapping cell values to column keys
    # - Organizing cells into summary vs round-specific sections
    # - Merging with JSON scorecard data
    # - Cleaning Golf Genius API data bugs
    #
    # @example Decompose row
    #   decomposer = GolfGenius::Scoreboard::RowDecomposer.new(row, column_structure)
    #   result = decomposer.decompose
    #   # => {
    #   #   id: 1001,
    #   #   name: "Player A",
    #   #   summary: { position: "1", ... },
    #   #   rounds: { 2001 => { thru: "8", scorecard: {...} } }
    #   # }
    #
    class RowDecomposer
      # Creates a new row decomposer.
      #
      # @param row [Hash] merged row data from DataMerger
      # @param column_structure [Hash] decomposed column structure from ColumnDecomposer
      #
      def initialize(row, column_structure)
        @row = row
        @column_structure = column_structure
      end

      # Decomposes the row into summary and round-specific sections.
      #
      # @return [Hash] decomposed row
      #
      def decompose
        {
          id: @row[:id],
          name: @row[:name],
          player_ids: @row[:player_ids],
          affiliation: @row[:affiliation],
          cut: @row[:cut],
          summary: build_summary_cells,
          rounds: build_rounds_cells,
        }
      end

      private

      # Builds summary cells hash.
      #
      # Maps cell values to summary column keys.
      #
      # @return [Hash] hash of column_key => cell_value
      #
      def build_summary_cells
        result = {}
        cells = @row[:cells] || []

        summary_cols = @column_structure[:summary] || []
        summary_cols.each do |col|
          next if col[:index] >= cells.length

          cell_value = normalize_cell_value(cells[col[:index]])
          result[col[:key].to_sym] = cell_value unless cell_value.nil?
        end

        result
      end

      # Builds rounds cells hash.
      #
      # Maps cell values to round-specific column keys and merges with scorecard data.
      # Also cleans Golf Genius API data bugs.
      #
      # @return [Hash] hash of round_id => { column_key => cell_value, scorecard: {...} }
      #
      def build_rounds_cells
        result = {}
        cells = @row[:cells] || []
        summary = build_summary_cells

        rounds = @column_structure[:rounds] || []
        rounds.each do |round|
          round_id = round[:id]
          round_cells = {}

          # Map HTML cell values to round column keys
          round[:columns].each do |col|
            next if col[:index] >= cells.length

            cell_value = normalize_cell_value(cells[col[:index]])
            round_cells[col[:key].to_sym] = cell_value unless cell_value.nil?
          end

          # Merge with scorecard data from JSON (if present)
          json_round_data = @row[:rounds][round_id]
          round_cells[:scorecard] = json_round_data[:scorecard] if json_round_data

          # Clean data bugs (duplicate totals, status codes in score fields).
          # WD players are excluded — their display is handled by Row#wd_round_strokes_value.
          clean_round_data!(round_cells, summary) unless withdrew?(summary)

          # Only include round if there's data
          result[round_id] = round_cells unless round_cells.empty?
        end

        result
      end

      # Cleans data bugs in round data.
      #
      # The data source sometimes produces bad values in unplayed rounds:
      # - Duplicate of tournament total instead of empty (any non-WD player)
      # - Status codes ("CUT", "DQ") in score fields (eliminated players)
      #
      # @param round_cells [Hash] the round cells to clean
      # @param summary [Hash] the summary cells (for total_gross comparison)
      #
      def clean_round_data!(round_cells, summary)
        total = round_cells[:total]
        return unless total

        total_gross = summary[:total_gross]

        # Bug 1: Round total equals tournament total (obvious duplicate)
        if total_gross && total.to_s == total_gross.to_s
          round_cells[:total] = nil
          return
        end

        # Bug 2: Total contains status code instead of score
        return unless total.to_s.match?(/^(CUT|DQ|MC|NS|NC)$/i)

        round_cells[:total] = nil
      end

      # Normalizes a raw HTML cell value.
      #
      # The HTML table uses "-" to represent empty/no-data cells.
      # We normalize these to nil so downstream code doesn't need
      # to handle display artifacts from the source.
      #
      # @param value [String, nil] the raw cell value
      # @return [String, nil] the value, or nil if it was a dash placeholder
      #
      def normalize_cell_value(value)
        return nil if value.nil?
        return nil if value.to_s.strip == "-"

        value
      end

      # Checks if player is eliminated based on summary position.
      #
      # @param summary [Hash] summary cells
      # @return [Boolean] true if eliminated
      #
      def eliminated?(summary)
        pos = summary[:position]
        return false if pos.nil?

        %w[CUT MC WD DQ NS NC].include?(pos.to_s.upcase)
      end

      # Checks if player withdrew based on summary position.
      #
      # @param summary [Hash] summary cells
      # @return [Boolean] true if withdrew
      #
      def withdrew?(summary)
        pos = summary[:position]
        return false if pos.nil?

        pos.to_s.upcase == "WD"
      end
    end
  end
end
