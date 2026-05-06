# frozen_string_literal: true

require_relative "round"

module GolfGenius
  class Scoreboard
    # Normalizes parsed tournament-results JSON into the shape expected by the
    # rest of the scoreboard pipeline.
    #
    # This is the integration layer between raw parsing and downstream merging:
    # - fills in round metadata from event rounds when the payload omits it
    # - synthesizes fetched-round row metadata when only aggregate-level summary
    #   fields are available
    class TournamentResultsNormalizer
      def initialize(json_data, fetched_round_id:, fallback_rounds:)
        @json_data = json_data
        @fetched_round_id = fetched_round_id.to_i
        @fallback_rounds = fallback_rounds
      end

      def normalize
        @json_data.merge(
          rounds: normalized_rounds,
          aggregates: normalized_aggregates
        )
      end

      private

      def normalized_rounds
        payload_rounds = @json_data[:rounds] || []
        return normalize_round_collection(@fallback_rounds) if payload_rounds.empty?

        fallback_by_id = rounds_by_id(@fallback_rounds)
        payload_by_id = rounds_by_id(payload_rounds)

        ordered_ids = (@fallback_rounds.map { |round| round[:id] } + payload_rounds.map { |round| round[:id] }).uniq

        ordered_ids.map do |round_id|
          payload_round = payload_by_id[round_id] || {}
          fallback_round = fallback_by_id[round_id] || {}

          merge_round(payload_round, fallback_round)
        end
      end

      def normalize_round_collection(rounds)
        rounds.map do |round|
          round.merge(name: canonical_round_name(round[:name], round[:index]))
        end
      end

      def rounds_by_id(rounds)
        rounds.each_with_object({}) do |round, result|
          result[round[:id]] = round
        end
      end

      def normalized_aggregates
        (@json_data[:aggregates] || {}).transform_values do |aggregate|
          normalize_aggregate(aggregate)
        end
      end

      def normalize_aggregate(aggregate)
        rounds = aggregate[:rounds] || {}
        return aggregate if rounds[@fetched_round_id]

        synthesized_round = synthesize_fetched_round(aggregate)
        return aggregate unless synthesized_round

        aggregate.merge(rounds: rounds.merge(@fetched_round_id => synthesized_round))
      end

      def merge_round(payload_round, fallback_round)
        # Event metadata is authoritative for progression fields because the
        # tournament_results payload can omit or stale-status them. The payload
        # remains authoritative for the display name when it is present.
        merged = fallback_round.merge(payload_round)
        merged_name = payload_round[:name] || fallback_round[:name]
        merged_index = payload_round[:index] || fallback_round[:index]

        merged[:name] = canonical_round_name(
          merged_name,
          merged_index
        )
        merged[:status] = fallback_round[:status] || payload_round[:status]
        merged[:in_progress] = if fallback_round.key?(:in_progress)
                                 fallback_round[:in_progress]
                               else
                                 payload_round[:in_progress]
                               end
        merged[:date] = fallback_round[:date] || payload_round[:date]
        merged[:index] = fallback_round[:index] || payload_round[:index]

        merged
      end

      def canonical_round_name(name, index)
        round_number = Round.extract_number(name) || index
        return name unless round_number

        "R#{round_number}"
      end

      def synthesize_fetched_round(aggregate)
        summary = aggregate[:current_round_summary] || {}
        return nil unless round_summary_present?(summary, aggregate[:current_round_scores])

        {
          thru: current_round_thru(aggregate[:current_round_scores]),
          score: summary[:score],
          total: summary[:total],
          status: current_round_status(aggregate[:current_round_scores]),
        }
      end

      def round_summary_present?(summary, scores)
        total_present = !summary[:total].to_s.strip.empty?
        gross_scores = scores&.dig(:gross_scores) || []
        totals = scores&.dig(:totals) || {}

        total_present ||
          gross_scores.compact.any? ||
          !totals[:out].nil? ||
          !totals[:in].nil? ||
          !totals[:total].nil?
      end

      def current_round_status(scores)
        gross_scores = scores&.dig(:gross_scores) || []
        holes_completed = gross_scores.compact.size
        totals = scores&.dig(:totals) || {}

        if current_round_completed?(gross_scores, totals)
          "completed"
        elsif holes_completed.positive?
          "partial"
        end
      end

      def current_round_thru(scores)
        gross_scores = scores&.dig(:gross_scores) || []
        holes_completed = gross_scores.compact.size
        status = current_round_status(scores)

        if status == "completed"
          "F"
        elsif holes_completed.positive?
          holes_completed.to_s
        end
      end

      def current_round_completed?(gross_scores, totals)
        return true if gross_scores.any? && gross_scores.none?(&:nil?)

        !totals[:out].nil? && !totals[:in].nil? && !totals[:total].nil?
      end
    end
  end
end
