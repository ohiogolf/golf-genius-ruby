# frozen_string_literal: true

module GolfGenius
  class Scoreboard
    # Decomposes columns into summary and round-specific sections.
    #
    # This class is responsible for:
    # - Identifying which columns are summary (cumulative/identity)
    # - Identifying which columns belong to specific rounds
    # - Generating column keys from format values
    # - Organizing columns by round
    #
    # @example Decompose columns
    #   decomposer = GolfGenius::Scoreboard::ColumnDecomposer.new(columns, rounds)
    #   result = decomposer.decompose
    #   # => {
    #   #   summary: [...],
    #   #   rounds: [...]
    #   # }
    #
    class ColumnDecomposer
      # Creates a new column decomposer.
      #
      # @param columns [Array<Hash>] array of column hashes from HTML parser
      # @param rounds [Array<Hash>] array of round metadata from JSON
      #
      def initialize(columns, rounds)
        @columns = columns
        @rounds = rounds
        @round_names_to_ids = build_round_name_lookup(rounds)
        @round_lookup = build_round_id_lookup(rounds)
      end

      # Decomposes columns into summary and round-specific sections.
      #
      # @return [Hash] hash with :summary and :rounds keys
      #
      def decompose
        summary_cols = []
        round_cols_by_id = Hash.new { |h, k| h[k] = [] }

        @columns.each_with_index do |col, index|
          round_id = identify_round(col)

          if round_id
            # Round-specific column
            round_name = @round_lookup[round_id][:name]
            round_cols_by_id[round_id] << build_column_hash(col, index, round_id: round_id, round_name: round_name)
          else
            # Summary column
            summary_cols << build_column_hash(col, index, round_id: nil, round_name: nil)
          end
        end

        {
          summary: summary_cols,
          rounds: build_rounds_structure(round_cols_by_id),
        }
      end

      private

      # Builds a lookup hash from round name to round ID.
      #
      # @param rounds [Array<Hash>] array of round metadata
      # @return [Hash] hash of round_name => round_id
      #
      def build_round_name_lookup(rounds)
        result = {}
        rounds.each do |round|
          result[round[:name]] = round[:id]
        end
        result
      end

      # Builds a lookup hash from round ID to round hash.
      #
      # @param rounds [Array<Hash>] array of round metadata
      # @return [Hash] hash of round_id => round_hash
      #
      def build_round_id_lookup(rounds)
        result = {}
        rounds.each do |round|
          result[round[:id]] = round
        end
        result
      end

      # Identifies which round (if any) a column belongs to.
      #
      # @param col [Hash] column hash from HTML parser
      # @return [Integer, nil] round ID or nil if summary column
      #
      def identify_round(col)
        # Check if column has a round_name attribute (from data-name)
        return @round_names_to_ids[col[:round_name]] if col[:round_name] && @round_names_to_ids[col[:round_name]]

        # Check if label contains a round name (e.g., "Thru R2", "R1")
        label = col[:label] || ""
        @round_names_to_ids.each do |round_name, round_id|
          return round_id if label.include?(round_name)
        end

        # No round association
        nil
      end

      # Builds a column hash for the output structure.
      #
      # @param col [Hash] raw column from HTML parser
      # @param index [Integer] column index (for debugging)
      # @param round_id [Integer, nil] the round ID if this is a round-scoped column
      # @param round_name [String, nil] the round name if this is a round-scoped column
      # @return [Hash] column hash with key, format, label, round_id, round_name
      #
      def build_column_hash(col, index, round_id:, round_name:)
        {
          key: generate_column_key(col[:format], !round_id.nil?),
          format: col[:format],
          label: col[:label],
          index: index, # Keep for mapping cells later
          round_id: round_id,
          round_name: round_name,
        }
      end

      # Generates a column key from the format.
      #
      # Converts format to snake_case. For round-scoped columns, removes the "round_"
      # prefix since they're already namespaced by round_id in the data structure.
      #
      # Examples:
      #   Summary: "total-to-par-gross" => "total_to_par_gross"
      #   Round:   "round-total" => "total" (prefix removed, accessed via rounds[round_id][:total])
      #   Round:   "to-par-gross" => "to_par_gross"
      #
      # @param format [String] the column format
      # @param round_scoped [Boolean] whether this is a round-scoped column
      # @return [String] the column key
      #
      def generate_column_key(format, round_scoped)
        # Convert to snake_case
        key = format.gsub("-", "_")

        # For round-scoped columns, strip "round_" prefix since these columns
        # are already namespaced by round_id (e.g., row.rounds[2001][:total])
        key = key.sub(/^round_/, "") if round_scoped

        key
      end

      # Builds the rounds structure with columns grouped by round.
      #
      # @param round_cols_by_id [Hash] hash of round_id => [columns]
      # @return [Array<Hash>] array of round hashes
      #
      def build_rounds_structure(round_cols_by_id)
        @rounds.map do |round|
          round_id = round[:id]
          columns = round_cols_by_id[round_id] || []

          {
            id: round_id,
            name: round[:name],
            in_progress: round[:in_progress],
            columns: columns,
          }
        end
      end
    end
  end
end
