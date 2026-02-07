# frozen_string_literal: true

module GolfGenius
  class Scoreboard
    # Decomposes row cells into summary and round-specific sections.
    #
    # This class is responsible for:
    # - Mapping cell values to column keys
    # - Organizing cells into summary vs round-specific sections
    # - Merging with JSON scorecard data
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

          cell_value = cells[col[:index]]
          result[col[:key].to_sym] = cell_value unless cell_value.nil?
        end

        result
      end

      # Builds rounds cells hash.
      #
      # Maps cell values to round-specific column keys and merges with scorecard data.
      #
      # @return [Hash] hash of round_id => { column_key => cell_value, scorecard: {...} }
      #
      def build_rounds_cells
        result = {}
        cells = @row[:cells] || []

        rounds = @column_structure[:rounds] || []
        rounds.each do |round|
          round_id = round[:id]
          round_cells = {}

          # Map HTML cell values to round column keys
          round[:columns].each do |col|
            next if col[:index] >= cells.length

            cell_value = cells[col[:index]]
            round_cells[col[:key].to_sym] = cell_value unless cell_value.nil?
          end

          # Merge with scorecard data from JSON (if present)
          json_round_data = @row[:rounds][round_id]
          round_cells[:scorecard] = json_round_data[:scorecard] if json_round_data

          # Only include round if there's data
          result[round_id] = round_cells unless round_cells.empty?
        end

        result
      end
    end
  end
end
