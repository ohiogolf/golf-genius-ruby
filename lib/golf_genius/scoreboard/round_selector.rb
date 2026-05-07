# frozen_string_literal: true

require_relative "round"

module GolfGenius
  class Scoreboard
    # Centralizes round ordering and fallback selection so the table schema and
    # detailed payload use the same notion of current and source round.
    module RoundSelector
      module_function

      def select_current(rounds)
        rounds_list = normalize_rounds(rounds)

        select_latest_round(rounds_list, &:playing?) ||
          select_latest_round(rounds_list, &:complete?) ||
          select_earliest_round(rounds_list, &:unstarted?) ||
          rounds_list.max_by { |round| round_order_key(round) }
      end

      def fallback_source_round(rounds, requested_round_id)
        rounds_list = normalize_rounds(rounds)
        requested_round = rounds_list.find { |round| round.id.to_i == requested_round_id.to_i }
        return nil unless requested_round

        rounds_list
          .select { |round| round.started? && round.id.to_i != requested_round_id.to_i }
          .select { |round| older_than_round?(round, requested_round) }
          .max_by { |round| round_order_key(round) }
      end

      def normalize_rounds(rounds)
        Array(rounds).map do |round|
          # Rounds may arrive as raw hashes, Scoreboard::Round wrappers, or
          # duck-typed event round resources responding to the round predicate
          # contract used below.
          if round.is_a?(Round) || responds_to_round_contract?(round)
            round
          elsif round.is_a?(Hash)
            Round.new(round)
          else
            raise ArgumentError, "round must be a Hash, Scoreboard::Round, or round-like object"
          end
        end
      end

      def round_order_key(round)
        [
          round_value(round, :index) || 0,
          round_value(round, :date) || "",
          round.id.to_i,
        ]
      end

      def select_latest_round(rounds_list, &block)
        rounds_list.select(&block).max_by { |round| round_order_key(round) }
      end

      def select_earliest_round(rounds_list, &block)
        rounds_list.select(&block).min_by { |round| round_order_key(round) }
      end

      def older_than_round?(round, other_round)
        (round_order_key(round) <=> round_order_key(other_round)) == -1
      end

      def round_value(round, key)
        return round[key] || round[key.to_s] if round.respond_to?(:[]) && !round.is_a?(Round)

        round.public_send(key) if round.is_a?(Round)
      end

      def responds_to_round_contract?(round)
        %i[id playing? complete? unstarted? started?].all? { |method_name| round.respond_to?(method_name) }
      end

      private_class_method(
        :round_order_key,
        :select_latest_round,
        :select_earliest_round,
        :older_than_round?,
        :round_value,
        :responds_to_round_contract?
      )
    end
  end
end
