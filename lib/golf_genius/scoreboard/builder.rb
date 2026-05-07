# frozen_string_literal: true

require_relative "entry_round_builder"
require_relative "location_builder"
require_relative "parallel_fetcher"
require_relative "player_builder"
require_relative "round"
require_relative "round_selector"
require_relative "schema_values"
require_relative "value_normalizer"

module GolfGenius
  class Scoreboard
    # Builds the primary, JSON-first scoreboard payload.
    class Builder
      def initialize(event_id:, requested_round_id:, tournament_ids:, json_loader:, event_context:)
        @event_id = event_id
        @requested_round_id = requested_round_id.to_i
        @tournament_ids = Array(tournament_ids)
        @json_loader = json_loader
        @event_name = event_context[:name]
        @rounds = event_context[:rounds]
        @round_objects = RoundSelector.normalize_rounds(@rounds)
      end

      def build
        context = fetch_context

        {
          meta: build_meta,
          rounds: build_rounds,
          tournaments: build_tournaments(context),
        }
      end

      private

      def fetch_context
        context = ParallelFetcher.fetch_hash(
          roster: -> { GolfGenius::Event.roster(@event_id) },
          tee_sheet: -> { GolfGenius::Event.tee_sheet(@event_id, @requested_round_id, include_all_custom_fields: true) }
        )

        context[:roster_lookup] = PlayerBuilder.build_roster_lookup(context[:roster])
        context[:tee_lookup] = PlayerBuilder.build_tee_lookup(context[:tee_sheet])
        context[:tournaments] = ParallelFetcher.map(@tournament_ids) do |tournament_id|
          json_data, source_round_id = @json_loader.call(tournament_id)
          {
            tournament_id: tournament_id.to_s,
            json_data: json_data,
            source_round_id: source_round_id.to_s,
          }
        end

        context
      end

      def build_meta
        {
          event_id: @event_id.to_s,
          event_name: ValueNormalizer.normalize_text(@event_name),
          selected_round: round_reference(@requested_round_id),
          current_round: round_reference(current_round&.id),
        }
      end

      def build_rounds
        @round_objects.map { |round| round_reference(round.id) }
      end

      def build_tournaments(context)
        context[:tournaments].map do |tournament_context|
          json_data = tournament_context[:json_data]

          {
            id: tournament_context[:tournament_id],
            name: json_data[:name],
            adjusted: json_data[:adjusted],
            source_round: round_reference(tournament_context[:source_round_id]),
            cut_list_position: json_data[:cut_list_position],
            display_cut: json_data[:display_cut],
            horizontal_leaderboard: json_data[:horizontal_leaderboard],
            columns: json_data[:columns],
            entries: build_entries(
              json_data,
              source_round_id: tournament_context[:source_round_id],
              roster_lookup: context[:roster_lookup],
              tee_lookup: context[:tee_lookup]
            ),
          }
        end
      end

      def build_entries(json_data, source_round_id:, roster_lookup:, tee_lookup:)
        aggregates = json_data[:aggregates] || {}
        entries = aggregates.values.map do |aggregate|
          build_aggregate_entry(
            aggregate,
            source_round_id: source_round_id,
            roster_lookup: roster_lookup,
            tee_lookup: tee_lookup
          )
        end

        return entries if entries.any?
        # Prestart synthesis currently assumes one tournament-results stream for
        # the event. If an event exposes multiple scoring tournaments and none
        # has aggregates yet, return no synthetic entries rather than guessing
        # how to partition tee-sheet players across tournaments.
        return [] unless @tournament_ids.one?

        build_prestart_entries(
          source_round_id: source_round_id,
          roster_lookup: roster_lookup,
          tee_lookup: tee_lookup
        )
      end

      def build_aggregate_entry(aggregate, source_round_id:, roster_lookup:, tee_lookup:)
        member_ids = Array(aggregate[:member_ids]).map(&:to_s)
        outcome = normalize_outcome(aggregate[:disposition], aggregate[:position])
        player_builder = build_player_builder(aggregate, member_ids, roster_lookup, tee_lookup)
        round_builder = build_entry_round_builder(aggregate, outcome, source_round_id, player_builder.player_contexts)
        rounds_payload = round_builder.rounds_payload
        entry_state = round_builder.entry_state
        outcome = sanitize_prestart_outcome(
          outcome,
          position: aggregate[:position],
          source_round_id: source_round_id,
          rounds_payload: rounds_payload
        )

        {
          id: aggregate[:id].to_s,
          scope_id: aggregate[:scope_id],
          name: aggregate[:name],
          position: aggregate[:position],
          rank: aggregate[:rank],
          state: entry_state,
          outcome: outcome,
          outcome_cause: ValueNormalizer.normalize_blank(aggregate[:disposition_cause]),
          details: ValueNormalizer.normalize_blank(aggregate[:details]),
          players: player_builder.players,
          rounds: rounds_payload,
        }
      end

      def build_prestart_entries(source_round_id:, roster_lookup:, tee_lookup:)
        Array(tee_lookup[:ordered_players]).map do |tee_player|
          roster_member = roster_member_for_tee_player(tee_player, roster_lookup)
          member_id = roster_member&.dig(:member_id) || tee_player[:player_roster_id]
          member_card_id = tee_player[:member_card_id]
          aggregate = {
            id: member_id || member_card_id || tee_player[:ggid] || tee_player[:name],
            name: roster_member&.dig(:name) || tee_player[:name],
            member_ids: Array(member_id).compact,
            member_cards: build_member_cards(member_id, member_card_id),
            affiliation: roster_member&.dig(:affiliation),
            countries: Array(roster_member&.dig(:country)).compact,
          }

          build_aggregate_entry(
            aggregate,
            source_round_id: source_round_id,
            roster_lookup: roster_lookup,
            tee_lookup: tee_lookup
          )
        end
      end

      def roster_member_for_tee_player(tee_player, roster_lookup)
        roster_lookup[:by_member_card_id][tee_player[:member_card_id]] ||
          roster_lookup[:by_member_id][tee_player[:player_roster_id]]
      end

      def build_member_cards(member_id, member_card_id)
        return [] if member_id.nil? && member_card_id.nil?

        [{
          member_id: member_id,
          member_card_id: member_card_id,
        }]
      end

      def sanitize_prestart_outcome(outcome, position:, source_round_id:, rounds_payload:)
        return outcome unless prestart_with_tee_time?(outcome, position, source_round_id.to_s, rounds_payload)

        nil
      end

      def prestart_with_tee_time?(outcome, position, source_round_id, rounds_payload)
        return false unless [SchemaValues::Outcome::DNS, SchemaValues::Outcome::NS].include?(outcome)
        return false unless ValueNormalizer.normalize_blank(position).nil?

        source_round = rounds_payload[source_round_id]
        return false unless source_round
        return false unless source_round[:state] == SchemaValues::State::NOT_STARTED

        !ValueNormalizer.normalize_blank(source_round[:tee_time]).nil?
      end

      def normalize_outcome(disposition, position = nil)
        value = disposition.to_s.strip
        position_value = position.to_s.strip
        # Golf Genius often emits elimination markers in position when
        # disposition is blank, so use position as the fallback source.
        value = position_value if value.empty? && outcome_code?(position_value)
        return nil if value.empty?

        SchemaValues::Outcome::FROM_GOLF_GENIUS.fetch(value.upcase, SchemaValues::Outcome::UNKNOWN)
      end

      def outcome_code?(value)
        SchemaValues::Outcome::FROM_GOLF_GENIUS.key?(value.upcase)
      end

      def canonical_round_name(round_data)
        Round.canonical_name(ValueNormalizer.normalize_text(round_data[:name]), round_data[:index])
      end

      def round_state(round)
        return SchemaValues::State::PLAYING if round.playing?
        return SchemaValues::State::FINISHED if round.complete?
        return SchemaValues::State::NOT_STARTED if round.unstarted?

        SchemaValues::State::UNKNOWN
      end

      def round_reference(round_id)
        round = @round_objects.find { |candidate| candidate.id.to_i == round_id.to_i }
        return nil unless round

        {
          id: round.id.to_s,
          name: canonical_round_name(round.to_h),
          date: round.date,
          state: round_state(round),
        }
      end

      def current_round
        @current_round ||= RoundSelector.select_current(@round_objects)
      end

      def build_player_builder(aggregate, member_ids, roster_lookup, tee_lookup)
        PlayerBuilder.new(
          aggregate: aggregate,
          member_ids: member_ids,
          roster_lookup: roster_lookup,
          tee_lookup: tee_lookup
        )
      end

      def build_entry_round_builder(aggregate, outcome, source_round_id, player_contexts)
        EntryRoundBuilder.new(
          aggregate: aggregate,
          outcome: outcome,
          round_context: {
            requested_round_id: @requested_round_id,
            source_round_id: source_round_id,
            rounds: @rounds,
          },
          player_contexts: player_contexts
        )
      end
    end
  end
end
