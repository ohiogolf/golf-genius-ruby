# frozen_string_literal: true

require_relative "scoreboard/round"
require_relative "scoreboard/builder"
require_relative "scoreboard/json_parser"
require_relative "scoreboard/round_selector"
require_relative "scoreboard/tournament_results_normalizer"

module GolfGenius
  # Scoreboard is a standalone service object that normalizes Golf Genius
  # tournament results into a JSON-first, round-aware payload.
  class Scoreboard
    attr_reader :event_id, :round_id, :tournament_id

    def initialize(event: nil, ggid: nil, round: nil, tournament: nil, schema: nil, skip_event_fetch: false)
      if event.nil? && ggid
        event = GolfGenius::Event.fetch_by(ggid: ggid)
        raise ArgumentError, "could not resolve ggid: #{ggid}" if event.nil?
      end

      raise ArgumentError, "event or ggid is required" if event.nil?

      @event_id = event.respond_to?(:id) ? event.id : event
      @round_id = round.respond_to?(:id) ? round.id : round
      @tournament_id = tournament.respond_to?(:id) ? tournament.id : tournament
      @event = event if event.respond_to?(:id)
      @skip_event_fetch = skip_event_fetch
      @schema = schema
    end

    # Returns the complete scoreboard payload as a hash.
    #
    # Shape:
    # - meta: event metadata plus selected/current round references
    # - rounds: event rounds with canonical state
    # - tournaments[]:
    #   - id, name, adjusted, source_round, columns
    #   - entries[]:
    #     - id, position, rank, state, outcome, details
    #     - players[] with normalized identity/location metadata
    #     - rounds[round_id] with per-entry round facts
    #
    # @return [Hash]
    def to_h
      @to_h ||= @schema || build_schema
    end

    # Returns a new Scoreboard with each tournament's entries sorted by the
    # requested keys.
    #
    # Supported keys:
    # - :competing
    # - :position
    # - :last_name
    #
    # @return [Scoreboard]
    def sort(*keys, direction: :asc)
      keys = %i[competing position] if keys.empty?

      sorted_schema = deep_dup(to_h)
      sorted_schema[:tournaments] = sorted_schema[:tournaments].map do |tournament|
        tournament.merge(
          entries: sort_entries(tournament[:entries], keys, direction)
        )
      end

      Scoreboard.new(
        event: @event_id,
        round: @round_id,
        tournament: @tournament_id,
        schema: sorted_schema
      )
    end

    private

    def build_schema
      resolve_round! unless @round_id
      resolve_tournaments! unless @tournament_ids

      event_obj = event

      Builder.new(
        event_id: @event_id,
        requested_round_id: @round_id.to_i,
        tournament_ids: @tournament_ids,
        json_loader: method(:fetch_json_for_tournament),
        event_context: {
          name: event_obj ? event_obj["name"] : @event_id.to_s,
          rounds: fallback_rounds_metadata,
        }
      ).build
    end

    def event
      return nil if @skip_event_fetch

      @event ||= GolfGenius::Event.fetch(@event_id)
    end

    def rounds
      @rounds ||= GolfGenius::Event.rounds(@event_id)
    end

    def fallback_rounds_metadata
      @fallback_rounds_metadata ||= rounds.map do |round|
        {
          id: round[:id]&.to_i,
          name: round[:name],
          date: round[:date],
          status: round[:status] || round["status"],
          index: round[:index] || round["index"],
          in_progress: round[:in_progress] || false,
        }
      end
    end

    def fetch_json_for_tournament(tournament_id)
      requested_round_id = @round_id.to_i
      requested_json = parse_tournament_results_json(tournament_id, requested_round_id)
      return [requested_json, requested_round_id] if requested_json[:aggregates].any?

      fallback_round = fallback_source_round_for(requested_round_id)
      return [requested_json, requested_round_id] unless fallback_round

      fallback_round_id = fallback_round.id.to_i
      fallback_json = parse_tournament_results_json(tournament_id, fallback_round_id)

      if fallback_json[:aggregates].any?
        [fallback_json, fallback_round_id]
      else
        [requested_json, requested_round_id]
      end
    end

    def parse_tournament_results_json(tournament_id, fetched_round_id)
      json_obj = GolfGenius::Event.tournament_results(@event_id, fetched_round_id, tournament_id, format: :json)
      json_string = json_obj.to_json(raw: true)
      json_parser = JsonParser.new(json_string)

      TournamentResultsNormalizer.new(
        json_parser.parse,
        fetched_round_id: fetched_round_id,
        fallback_rounds: fallback_rounds_metadata
      ).normalize
    end

    def fallback_source_round_for(requested_round_id)
      RoundSelector.fallback_source_round(rounds, requested_round_id)
    end

    def resolve_round!
      rounds_list = rounds

      raise StandardError, "No rounds found for event #{@event_id}" if rounds_list.nil? || rounds_list.empty?

      @round_id = RoundSelector.select_current(rounds_list).id
    end

    def resolve_tournaments!
      all_tournaments = GolfGenius::Event.tournaments(@event_id, @round_id)

      if all_tournaments.nil? || all_tournaments.empty?
        raise StandardError, "No tournaments found for event #{@event_id}, round #{@round_id}"
      end

      scoring_tournaments = all_tournaments.reject(&:non_scoring?)

      if scoring_tournaments.empty?
        raise StandardError, "No scoring tournaments found for event #{@event_id}, round #{@round_id}"
      end

      @tournament_ids = if @tournament_id
                          [@tournament_id]
                        else
                          scoring_tournaments.map(&:id)
                        end
    end

    def sort_entries(entries, keys, direction)
      entries.sort do |entry_a, entry_b|
        compare_entries(entry_a, entry_b, keys, direction)
      end
    end

    def compare_entries(entry_a, entry_b, keys, direction)
      keys.each do |key|
        result = case key
                 when :position
                   compare_positions(entry_a[:position], entry_b[:position])
                 when :last_name
                   compare_strings(last_name_for(entry_a), last_name_for(entry_b))
                 when :competing
                   compare_competing(entry_a, entry_b)
                 else
                   raise ArgumentError, "Unknown sort key: #{key}"
                 end

        result = -result if direction == :desc
        return result unless result.zero?
      end

      0
    end

    def compare_positions(pos_a, pos_b)
      position_sort_value(pos_a) <=> position_sort_value(pos_b)
    end

    def position_sort_value(position)
      return [3, ""] if position.nil? || position.to_s.strip.empty?

      pos = position.to_s.strip.upcase

      if pos.start_with?("T")
        numeric = Integer(pos[1..], exception: false)
        return [1, numeric] if numeric&.positive?
      end

      numeric = Integer(pos, exception: false)
      return [1, numeric] if numeric&.positive?

      [2, pos]
    end

    def compare_strings(str_a, str_b)
      a_empty = str_a.nil? || str_a.to_s.strip.empty?
      b_empty = str_b.nil? || str_b.to_s.strip.empty?

      return 0 if a_empty && b_empty
      return 1 if a_empty
      return -1 if b_empty

      str_a.to_s.downcase <=> str_b.to_s.downcase
    end

    def compare_competing(entry_a, entry_b)
      a_competing = entry_a[:outcome].nil?
      b_competing = entry_b[:outcome].nil?

      return 0 if a_competing == b_competing
      return -1 if a_competing

      1
    end

    def last_name_for(entry)
      entry.dig(:players, 0, :name, :last) || entry[:name]
    end

    def deep_dup(value)
      case value
      when Hash
        value.transform_values { |nested_value| deep_dup(nested_value) }
      when Array
        value.map { |nested_value| deep_dup(nested_value) }
      else
        value
      end
    end
  end
end
