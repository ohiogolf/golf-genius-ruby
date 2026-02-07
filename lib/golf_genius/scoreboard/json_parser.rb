# frozen_string_literal: true

require "json"

module GolfGenius
  class Scoreboard
    # Parses JSON tournament results and extracts metadata.
    #
    # This parser is responsible for:
    # - Extracting tournament metadata (name, adjusted, rounds)
    # - Extracting row data for each player/team (called "aggregates" in Golf Genius API)
    # - Providing hole-by-hole scores and round-specific data
    #
    # The parser returns plain Ruby hashes, not custom objects.
    #
    # @example Parse JSON
    #   parser = GolfGenius::Scoreboard::JsonParser.new(json_string)
    #   result = parser.parse
    #   # => {
    #   #   name: "Tournament Name",
    #   #   adjusted: false,
    #   #   rounds: [...],
    #   #   aggregates: {...}
    #   # }
    #
    class JsonParser
      # @return [String] the JSON to parse
      attr_reader :json

      # Creates a new JSON parser.
      #
      # @param json [String] the JSON to parse
      # @raise [ArgumentError] if json is nil or empty
      # @raise [GolfGenius::ValidationError] if json is malformed
      #
      def initialize(json)
        raise ArgumentError, "json is required" if json.nil? || json.to_s.strip.empty?

        @json = json
        @data = JSON.parse(json)
      rescue JSON::ParserError => e
        raise GolfGenius::ValidationError, "Invalid JSON in tournament results: #{e.message}"
      end

      # Parses the JSON and returns the structured data.
      #
      # @return [Hash] parsed data with :name, :adjusted, :rounds, :aggregates
      #
      def parse
        {
          name: @data["name"],
          adjusted: @data["adjusted"] || false,
          rounds: parse_rounds,
          aggregates: parse_aggregates,
        }
      end

      private

      # Parses the rounds array from JSON.
      #
      # @return [Array<Hash>] array of round hashes with id, name, date, in_progress
      #
      def parse_rounds
        rounds = @data["rounds"] || []
        rounds.map do |round|
          {
            id: round["id"],
            name: round["name"],
            date: round["date"],
            in_progress: round["in_progress"] || false,
          }
        end
      end

      # Parses row data from all scopes.
      #
      # Returns a hash keyed by row ID for fast lookup.
      # Note: Golf Genius API calls these "aggregates".
      #
      # @return [Hash] hash of row_id => row_data
      #
      def parse_aggregates
        result = {}

        scopes = @data["scopes"] || []
        scopes.each do |scope|
          aggregates = scope["aggregates"] || []
          aggregates.each do |agg|
            result[agg["id"]] = parse_aggregate(agg)
          end
        end

        result
      end

      # Parses a single row's data.
      #
      # @param agg [Hash] the row data from JSON (called "aggregate" in API)
      # @return [Hash] parsed row data with rounds and scorecard data
      #
      def parse_aggregate(agg)
        {
          id: agg["id"],
          member_ids: agg["member_ids_str"] || [],
          rounds: parse_aggregate_rounds(agg),
          current_round_scores: parse_current_round_scores(agg),
          previous_rounds_scores: parse_previous_rounds_scores(agg),
        }
      end

      # Parses rounds array from a row's data.
      #
      # @param agg [Hash] the row data
      # @return [Hash] hash of round_id => round_data
      #
      def parse_aggregate_rounds(agg)
        result = {}

        rounds = agg["rounds"] || []
        rounds.each do |round|
          result[round["id"]] = {
            thru: round["thru"],
            score: round["score"],
            total: round["total"],
            status: extract_scorecard_status(round),
          }
        end

        result
      end

      # Extracts scorecard status from scorecard_statuses array.
      #
      # Takes the first status value, assuming all match.
      #
      # @param round [Hash] the round data
      # @return [String, nil] the status string
      #
      def extract_scorecard_status(round)
        statuses = round["scorecard_statuses"] || []
        return nil if statuses.empty?

        statuses.first["status"]
      end

      # Parses current round hole-by-hole scores.
      #
      # These are the top-level arrays in the row data.
      #
      # @param agg [Hash] the row data
      # @return [Hash] hash with gross_scores, net_scores, to_par_gross, to_par_net, totals
      #
      def parse_current_round_scores(agg)
        {
          gross_scores: agg["gross_scores"] || [],
          net_scores: agg["net_scores"] || [],
          to_par_gross: agg["to_par_gross"] || [],
          to_par_net: agg["to_par_net"] || [],
          totals: parse_totals(agg["totals"]),
        }
      end

      # Parses previous rounds scores array.
      #
      # @param agg [Hash] the row data
      # @return [Hash] hash of round_id => scores_data
      #
      def parse_previous_rounds_scores(agg)
        result = {}

        previous = agg["previous_rounds_scores"] || []
        previous.each do |round|
          result[round["round_id"]] = {
            gross_scores: round["gross_scores"] || [],
            net_scores: round["net_scores"] || [],
            to_par_gross: round["to_par_gross"] || [],
            to_par_net: round["to_par_net"] || [],
            totals: parse_totals(round["totals"]),
          }
        end

        result
      end

      # Parses totals hash.
      #
      # @param totals [Hash, nil] the totals data
      # @return [Hash] hash with out, in, total for gross_scores
      #
      def parse_totals(totals)
        return { out: nil, in: nil, total: nil } unless totals

        gross = totals["gross_scores"] || {}
        {
          out: gross["out"],
          in: gross["in"],
          total: gross["total"],
        }
      end
    end
  end
end
