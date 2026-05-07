# frozen_string_literal: true

module GolfGenius
  class Scoreboard
    # Merges HTML and JSON data for tournament results.
    #
    # This class is responsible for:
    # - Matching HTML rows to JSON row data (aggregates) by ID
    # - Injecting JSON metadata into round-level data
    # - Organizing data into summary vs round-specific sections
    #
    # @example Merge data
    #   merger = GolfGenius::Scoreboard::DataMerger.new(html_data, json_data, fetched_round_id)
    #   result = merger.merge
    #   # => {
    #   #   tournament_meta: {...},
    #   #   rows: [...]
    #   # }
    #
    class DataMerger
      # Creates a new data merger.
      #
      # @param html_data [Hash] parsed HTML data from HtmlParser
      # @param json_data [Hash] parsed JSON data from JsonParser
      # @param fetched_round_id [Integer] the round ID that was fetched from the API
      #
      def initialize(html_data, json_data, fetched_round_id)
        @html_data = html_data
        @json_data = json_data
        @fetched_round_id = fetched_round_id
      end

      # Merges HTML and JSON data.
      #
      # @return [Hash] merged data with tournament_meta and rows
      # @raise [StandardError] if data is inconsistent
      #
      def merge
        validate_data!

        {
          tournament_meta: build_tournament_meta,
          rows: merge_rows,
        }
      end

      private

      # Validates that HTML and JSON data are consistent.
      #
      # @raise [GolfGenius::ValidationError] if validation fails
      #
      def validate_data!
        html_rows = @html_data[:rows] || []
        json_rows = @json_data[:aggregates] || {}

        html_rows.each do |row|
          json_row = matching_json_row(row)

          if json_row.nil? && !json_rows.empty?
            raise GolfGenius::ValidationError, "HTML row #{row[:id]} (#{row[:name]}) has no matching JSON row data"
          end

          next unless json_row

          html_ids = normalize_ids(row[:player_ids])
          json_ids = normalize_ids(json_row[:member_ids])

          unless ids_match?(html_ids, json_ids)
            raise GolfGenius::ValidationError,
                  "Player ID mismatch for row #{row[:id]}: HTML has #{html_ids.inspect}, JSON has #{json_ids.inspect}"
          end
        end
      end

      # Builds tournament metadata from JSON.
      #
      # @return [Hash] tournament metadata
      #
      def build_tournament_meta
        {
          name: @json_data[:name],
          adjusted: @json_data[:adjusted],
          rounds: @json_data[:rounds],
          cut_text: @html_data[:cut_text],
        }
      end

      # Merges HTML rows with JSON row data.
      #
      # @return [Array<Hash>] array of merged row hashes
      #
      def merge_rows
        html_rows = @html_data[:rows] || []

        html_rows.map do |html_row|
          json_row = matching_json_row(html_row)
          merge_row(html_row, json_row)
        end
      end

      # Merges a single HTML row with its JSON row data.
      #
      # @param html_row [Hash] the HTML row data
      # @param json_row [Hash] the JSON row data
      # @return [Hash] merged row
      #
      def merge_row(html_row, json_row)
        {
          id: html_row[:id],
          name: html_row[:name],
          player_ids: html_row[:player_ids],
          affiliation: html_row[:affiliation],
          countries: json_row&.dig(:countries) || [],
          cut: html_row[:cut],
          cells: html_row[:cells],
          rounds: merge_rounds_data(json_row),
        }
      end

      # Merges round data from JSON row data.
      #
      # Creates a hash keyed by round_id with scorecard metadata.
      #
      # @param json_row [Hash] the JSON row data
      # @return [Hash] hash of round_id => round_data
      #
      def merge_rounds_data(json_row)
        result = {}
        return result unless json_row

        # Get all rounds from JSON
        rounds = @json_data[:rounds] || []

        rounds.each do |round|
          round_id = round[:id]
          round_data_from_json = json_row[:rounds][round_id.to_s]

          # Skip if no data for this round
          next unless round_data_from_json

          # Determine if this is the fetched round or a previous round
          if round_id == @fetched_round_id
            # Current/fetched round - use current_round_scores
            result[round_id] = {
              total: round_data_from_json[:total],
              scorecard: build_scorecard(round_data_from_json, json_row[:current_round_scores]),
            }
          else
            # Previous round - use previous_rounds_scores
            prev_scores = json_row[:previous_rounds_scores][round_id.to_s]
            if prev_scores
              result[round_id] = {
                total: round_data_from_json[:total],
                scorecard: build_scorecard(round_data_from_json, prev_scores),
              }
            end
          end
        end

        result
      end

      # Builds scorecard data from round data and scores.
      #
      # @param round_data [Hash] round data from JSON row.rounds
      # @param scores [Hash] scores data (current or previous round)
      # @return [Hash] scorecard hash
      #
      def build_scorecard(round_data, scores)
        {
          thru: round_data[:thru],
          score: round_data[:score],
          status: round_data[:status],
          gross_scores: scores&.dig(:gross_scores) || [],
          net_scores: scores&.dig(:net_scores) || [],
          to_par_gross: scores&.dig(:to_par_gross) || [],
          to_par_net: scores&.dig(:to_par_net) || [],
          totals: scores&.dig(:totals) || {},
        }
      end

      def matching_json_row(html_row)
        direct_match = @json_data[:aggregates][html_row[:id]]
        return direct_match if ids_match?(html_row[:player_ids], direct_match&.[](:member_ids))
        return direct_match if direct_match && normalize_ids(html_row[:player_ids]).empty?

        matches = member_id_matches_for(html_row)
        return direct_match if matches.empty? && direct_match
        return nil if matches.empty?
        return matches.first if matches.one?

        raise GolfGenius::ValidationError,
              "HTML row #{html_row[:id]} (#{html_row[:name]}) matches multiple JSON rows by member ids"
      end

      def member_id_matches_for(html_row)
        normalized_html_ids = normalize_ids(html_row[:player_ids])
        return [] if normalized_html_ids.empty?

        (@json_data[:aggregates] || {}).values.select do |json_row|
          ids_match?(normalized_html_ids, json_row[:member_ids])
        end
      end

      def ids_match?(html_ids, json_ids)
        normalize_ids(html_ids) == normalize_ids(json_ids)
      end

      def normalize_ids(ids)
        Array(ids).filter_map do |value|
          id = value.to_s.strip
          id.empty? ? nil : id
        end.sort
      end
    end
  end
end
