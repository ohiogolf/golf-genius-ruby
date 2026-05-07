# frozen_string_literal: true

require "cgi"
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
          name: normalize_text(@data["name"]),
          adjusted: @data["adjusted"] || false,
          cut_list_position: parse_cut_list_position,
          display_cut: @data["display_cut"] || false,
          horizontal_leaderboard: @data["horizontal_leaderboard"] || false,
          columns: parse_columns,
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
            name: normalize_text(round["name"]),
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
            result[agg["id"]] = parse_aggregate(agg, scope)
          end
        end

        result
      end

      # Parses a single row's data.
      #
      # @param agg [Hash] the row data from JSON (called "aggregate" in API)
      # @return [Hash] parsed row data with rounds and scorecard data
      #
      def parse_aggregate(agg, scope)
        {
          id: agg["id"],
          scope_id: scope["id"]&.to_s,
          name: normalize_text(agg["name"]),
          position: normalize_text(agg["position"]),
          rank: parse_integer(agg["rank"]),
          affiliation: normalize_text(agg["affiliation"]),
          details: normalize_blank(agg["details"]),
          disposition: normalize_blank(agg["disposition"]),
          disposition_cause: normalize_blank(agg["disposition_cause"]),
          tour_id: normalize_blank(agg["tour_id"]),
          member_ids: parse_member_ids(agg),
          member_cards: parse_member_cards(agg),
          countries: parse_countries(agg),
          rounds: parse_aggregate_rounds(agg),
          scorecard_statuses: parse_scorecard_statuses(agg["scorecard_statuses"]),
          current_round_summary: parse_current_round_summary(agg),
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
          result[round["id"].to_s] = {
            thru: normalize_blank(round["thru"]),
            score: normalize_blank(round["score"]),
            total: normalize_blank(round["total"]),
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

        normalize_blank(statuses.first["status"])
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

      # Parses aggregate-level summary fields for the fetched/current round.
      #
      # Some tournament_results payloads omit the per-round "rounds" array entirely
      # but still expose the current round at the aggregate top level. This captures
      # the raw summary fields needed for downstream normalization.
      #
      # @param agg [Hash] the row data
      # @return [Hash] hash with score, total
      #
      def parse_current_round_summary(agg)
        {
          thru: normalize_blank(agg["thru"]),
          score: normalize_blank(agg["score"]),
          total: normalize_blank(agg["total"]),
          status: parse_scorecard_statuses(agg["scorecard_statuses"]).first,
        }
      end

      def parse_member_cards(agg)
        raw_cards = agg["member_cards"] || []

        Array(raw_cards).map do |entry|
          {
            member_id: entry["member_id"]&.to_s,
            member_card_id: entry["member_card_id"]&.to_s,
          }
        end
      end

      def parse_member_ids(agg)
        raw_ids = agg["member_ids_str"]
        raw_ids = agg["member_ids"] if raw_ids.nil?

        Array(raw_ids)
          .filter_map do |value|
            id = value.to_s.strip
            id.empty? ? nil : id
          end
      end

      def parse_scorecard_statuses(statuses)
        Array(statuses).filter_map do |status|
          normalize_blank(status["status"])
        end
      end

      def parse_countries(agg)
        countries = case agg["country"]
                    when Array
                      agg["country"]
                    when Hash
                      [agg["country"]]
                    else
                      Array(agg["country"]).compact
                    end

        # rubocop:disable Naming/VariableNumber
        countries.map do |country|
          {
            name: country["name"],
            alpha_2: country["alpha_2"],
            alpha_3: country["alpha_3"],
            ioc: country["ioc"],
          }
        end
        # rubocop:enable Naming/VariableNumber
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
          result[round["round_id"].to_s] = {
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

      def parse_columns
        visibility = @data["column_visibility"] || {}
        names = @data["column_names"] || {}

        names.each_with_object({}) do |(key, label), result|
          result[key.to_s] = {
            label: clean_label(label),
            visible: visibility[key] || visibility[key.to_s] || false,
          }
        end
      end

      def parse_cut_list_position
        positions = Array(@data["scopes"]).filter_map { |scope| scope["cut_list_position"] }.uniq
        return nil if positions.empty?
        return positions.first if positions.one?

        positions
      end

      def clean_label(value)
        return nil if value.nil?

        decoded = CGI.unescape(CGI.unescapeHTML(value.to_s))
        without_tags = decoded.gsub(%r{<br\s*/?>}i, " ").gsub(/<[^>]+>/, " ")
        normalize_text(without_tags)
      end

      def normalize_text(value)
        return nil if value.nil?

        value.to_s.gsub(/\s+/, " ").strip
      end

      def normalize_blank(value)
        normalized = normalize_text(value)
        normalized == "" ? nil : normalized
      end

      def parse_integer(value)
        normalized = normalize_blank(value)
        return nil unless normalized
        return normalized.to_i if normalized.match?(/\A\d+\z/)

        normalized
      end
    end
  end
end
