# frozen_string_literal: true

require_relative "schema_values"
require_relative "scorecard"

module GolfGenius
  class Scoreboard
    # Builds per-entry round facts and derives the canonical entry state.
    class EntryRoundBuilder
      def initialize(aggregate:, outcome:, round_context:, player_contexts:)
        @aggregate = aggregate
        @outcome = outcome
        @requested_round_id = round_context[:requested_round_id].to_s
        @source_round_id = round_context[:source_round_id].to_s
        @rounds = round_context[:rounds]
        @player_contexts = player_contexts
      end

      def entry_state
        return SchemaValues::State::ELIMINATED if eliminated_outcome?

        if [SchemaValues::Outcome::DNS, SchemaValues::Outcome::NS].include?(@outcome)
          return SchemaValues::State::NOT_STARTED
        end

        round_summary = aggregate_round_summary(@source_round_id)
        scorecard_data =
          if round_summary
            build_scorecard_data(
              round_summary,
              round_scores_for(@source_round_id)
            )
          elsif @source_round_id == @requested_round_id
            build_tee_sheet_scorecard(primary_tee_player)
          end

        return SchemaValues::State::UNKNOWN unless scorecard_data

        Scorecard.new(scorecard_data).state.to_s
      end

      def rounds_payload
        tee_player = primary_tee_player

        @rounds.each_with_object({}) do |round_data, result|
          round_id = round_data[:id].to_s
          round_hash = round_payload_for(round_id, tee_player)
          next unless round_hash

          result[round_id] = round_hash
        end
      end

      private

      def round_payload_for(round_id, tee_player)
        round_summary = aggregate_round_summary(round_id)
        scorecard_data =
          if round_summary
            build_scorecard_data(
              round_summary,
              round_scores_for(round_id)
            )
          elsif round_id == @requested_round_id
            build_tee_sheet_scorecard(tee_player)
          end

        return nil unless scorecard_data

        scorecard = Scorecard.new(scorecard_data)

        {
          state: round_state_for(scorecard),
          thru: scorecard.thru,
          to_par_display: scorecard.score,
          to_par_total: normalized_to_par_total(scorecard),
          tee_time: tee_player&.dig(:tee_time),
          starting_hole: tee_player&.dig(:starting_hole),
          gross_scores: scorecard.gross_scores,
          net_scores: scorecard.net_scores,
          gross_to_par: scorecard.to_par_gross,
          net_to_par: scorecard.to_par_net,
          stroke_totals: normalize_totals(
            scorecard.totals,
            fallback_total: scorecard_data[:total],
            gross_scores: scorecard.gross_scores
          ),
        }
      end

      def primary_tee_player
        # Golf Genius tee-sheet data is entry-level, not round-specific, so use
        # the first matched tee context across all rounds for this entry.
        @primary_tee_player ||=
          @player_contexts
          .lazy
          .map { |player_context| player_context[:tee_player] }
          .find(&:itself)
      end

      def round_scores_for(round_id)
        if round_id == @source_round_id
          @aggregate[:current_round_scores]
        else
          @aggregate[:previous_rounds_scores][round_id] || {}
        end
      end

      def aggregate_round_summary(round_id)
        rounds = @aggregate[:rounds] || {}
        rounds[round_id]
      end

      def build_scorecard_data(summary, scores)
        {
          thru: summary[:thru],
          score: summary[:score],
          total: summary[:total],
          status: summary[:status] || aggregate_status_fallback(scores),
          gross_scores: scores[:gross_scores] || [],
          net_scores: scores[:net_scores] || [],
          to_par_gross: scores[:to_par_gross] || [],
          to_par_net: scores[:to_par_net] || [],
          totals: scores[:totals] || {},
        }
      end

      def build_tee_sheet_scorecard(tee_player)
        return nil unless tee_player

        gross_scores = Array(tee_player[:score_array]).first(18)
        completed_holes = gross_scores.compact.size
        return nil if gross_scores.empty? && tee_player[:tee_time].nil?

        status =
          if completed_holes.zero?
            "no_holes"
          elsif gross_scores.compact.size == 18 && gross_scores.none?(&:nil?)
            "completed"
          else
            "partial"
          end

        thru =
          if completed_holes.zero?
            nil
          elsif status == "completed"
            "F"
          else
            completed_holes.to_s
          end

        total = gross_scores.compact.sum if status == "completed"

        {
          thru: thru,
          score: nil,
          total: total,
          status: status,
          gross_scores: gross_scores,
          net_scores: [],
          to_par_gross: [],
          to_par_net: [],
          totals: {
            out: nil,
            in: nil,
            total: total,
          },
        }
      end

      def aggregate_status_fallback(scores)
        return nil unless scores.is_a?(Hash)

        gross_scores = Array(scores[:gross_scores])
        return "completed" if gross_scores.any? && gross_scores.none?(&:nil?)
        return "partial" if gross_scores.compact.any?

        nil
      end

      def round_state_for(scorecard)
        if [SchemaValues::Outcome::DNS, SchemaValues::Outcome::NS].include?(@outcome)
          return SchemaValues::State::NOT_STARTED
        end

        scorecard.state.to_s
      end

      def normalize_totals(totals, fallback_total: nil, gross_scores: [])
        scores = Array(gross_scores)
        front_nine_scores = scores.first(9).compact
        back_nine_scores = scores.drop(9).first(9).compact
        all_scores = scores.compact
        normalized_out = normalize_total_value(totals[:out])
        normalized_in = normalize_total_value(totals[:in])
        normalized_total = normalize_total_value(totals[:total] || fallback_total)

        {
          out: normalized_out || (front_nine_scores.any? ? front_nine_scores.sum : nil),
          in: normalized_in || (back_nine_scores.any? ? back_nine_scores.sum : nil),
          total: normalized_total || (all_scores.any? ? all_scores.sum : nil),
        }
      end

      def normalize_total_value(value)
        return nil if value.nil?

        normalized = value.to_s.strip
        return nil if normalized.empty? || normalized == "-"
        return nil if SchemaValues::Outcome::FROM_GOLF_GENIUS.key?(normalized.upcase)

        Integer(normalized, exception: false) || value
      end

      def eliminated_outcome?
        [
          SchemaValues::Outcome::CUT,
          SchemaValues::Outcome::WD,
          SchemaValues::Outcome::DQ,
          SchemaValues::Outcome::MC,
          SchemaValues::Outcome::NC,
        ].include?(@outcome)
      end

      def normalized_to_par_total(scorecard)
        scorecard.total_to_par || parse_to_par_display(scorecard.score)
      end

      def parse_to_par_display(value)
        display = value.to_s.strip.upcase
        return nil if display.empty? || display == "-"
        return 0 if display == "E"

        Integer(display, exception: false)
      end
    end
  end
end
