# frozen_string_literal: true

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
        rounds = @json_data[:rounds]
        return rounds if rounds && !rounds.empty?

        @fallback_rounds
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
