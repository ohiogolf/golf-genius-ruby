# frozen_string_literal: true

require_relative "scoreboard/html_parser"
require_relative "scoreboard/json_parser"
require_relative "scoreboard/data_merger"
require_relative "scoreboard/column_decomposer"
require_relative "scoreboard/row_decomposer"
require_relative "scoreboard/tournament"

module GolfGenius
  # Scoreboard is a standalone service object that normalizes Golf Genius tournament
  # results into a semantic, round-aware table structure.
  #
  # The Scoreboard eagerly fetches all tournaments for an event/round, parses HTML
  # as the source of truth for table structure, and supplements with JSON metadata
  # (hole-by-hole scores, scorecard statuses, cut positions, etc.).
  #
  # @example Fetch latest results for an event
  #   scoreboard = GolfGenius::Scoreboard.new(event_id: "522157")
  #   scoreboard.to_h
  #   # => { meta: { ... }, tournaments: [ ... ] }
  #
  # @example Fetch specific round and tournament
  #   scoreboard = GolfGenius::Scoreboard.new(
  #     event_id: "522157",
  #     round_id: "1615931",
  #     tournament_id: "4522280"
  #   )
  #
  class Scoreboard
    # @return [String] the event ID
    attr_reader :event_id

    # @return [String, nil] the round ID (nil if not yet resolved)
    attr_reader :round_id

    # @return [String, nil] the tournament ID filter (nil if fetching all tournaments)
    attr_reader :tournament_id

    # Creates a new Scoreboard instance.
    #
    # @param event [GolfGenius::Event, String] the event object or event ID (required)
    # @param round [GolfGenius::Round, String, nil] the round object or round ID (optional)
    # @param tournament [GolfGenius::Tournament, String, nil] the tournament object or tournament ID (optional)
    # @param schema [Hash, nil] pre-built schema (for internal use, e.g., sorting)
    # @param skip_event_fetch [Boolean] if true, skips fetching event metadata (uses event_id as name)
    #
    # @raise [ArgumentError] if event is not provided
    #
    # @example With IDs
    #   scoreboard = GolfGenius::Scoreboard.new(event: "522157")
    #   scoreboard = GolfGenius::Scoreboard.new(event: "522157", round: "1615931")
    #   scoreboard = GolfGenius::Scoreboard.new(event: "522157", round: "1615931", tournament: "4522280")
    #
    # @example With objects
    #   scoreboard = GolfGenius::Scoreboard.new(event: event_obj)
    #   scoreboard = GolfGenius::Scoreboard.new(event: event_obj, round: round_obj)
    #
    # @example Skip event fetch (avoids 3-4 paginated API calls)
    #   scoreboard = GolfGenius::Scoreboard.new(event: "522157", skip_event_fetch: true)
    #
    def initialize(event:, round: nil, tournament: nil, schema: nil, skip_event_fetch: false)
      raise ArgumentError, "event is required" if event.nil?

      # Resolve IDs from objects or use strings directly
      @event_id = event.respond_to?(:id) ? event.id : event
      @round_id = round.respond_to?(:id) ? round.id : round
      @tournament_id = tournament.respond_to?(:id) ? tournament.id : tournament

      # If an event object was passed, memoize it to avoid fetching later
      @event = event if event.respond_to?(:id)

      # Performance optimization: skip event fetch if only ID is needed
      @skip_event_fetch = skip_event_fetch

      # Memoization
      @schema = schema
    end

    # Returns the complete scoreboard schema as a hash.
    #
    # The schema includes top-level metadata and an array of tournaments,
    # each with their own columns and rows.
    #
    # @return [Hash] the complete scoreboard schema
    #
    def to_h
      @to_h ||= @schema || build_schema
    end

    # Returns all tournaments as Tournament objects.
    #
    # @return [Array<Tournament>] array of Tournament objects
    #
    def tournaments
      @tournaments ||= to_h[:tournaments].map { |t| Tournament.new(t) }
    end

    # Returns a specific tournament by ID or name.
    #
    # @param identifier [Integer, String] tournament ID or name
    # @return [Tournament, nil] Tournament object or nil if not found
    #
    def tournament(identifier)
      tournaments.find do |t|
        t.tournament_id == identifier.to_i ||
          t.name == identifier ||
          t.name&.downcase&.include?(identifier.to_s.downcase)
      end
    end

    # Returns all rows across all tournaments as Row objects.
    #
    # Each row is decorated with tournament_id so the caller knows its origin.
    #
    # @return [Array<Row>] array of Row objects
    #
    def rows
      tournaments.flat_map(&:rows)
    end

    # Returns a new Scoreboard with all tournaments sorted by the given criteria.
    #
    # Sorts all tournaments in the scoreboard using the same sort keys and direction.
    # Returns a new Scoreboard instance with sorted data; the original is unchanged.
    #
    # @param keys [Array<Symbol>] sort keys (:position, :last_name, :competing)
    # @param direction [Symbol] sort direction (:asc or :desc)
    # @return [Scoreboard] new Scoreboard with sorted tournaments
    #
    # @example Default sort (competing players first, then by position)
    #   sorted = scoreboard.sort
    #   sorted = scoreboard.sort(:competing, :position)  # explicit
    #
    # @example Sort alphabetically by last name
    #   alpha = scoreboard.sort(:last_name)
    #
    # @example Competing players first, then alphabetically
    #   sorted = scoreboard.sort(:competing, :last_name)
    #
    # @example Sort by position descending (worst first)
    #   sorted = scoreboard.sort(:position, direction: :desc)
    #
    # @example Multi-key sort (position, then last name for ties)
    #   sorted = scoreboard.sort(:position, :last_name)
    #
    def sort(*keys, direction: :asc)
      # Default to competing players first, then by position
      keys = %i[competing position] if keys.empty?

      # Build sorted schema
      sorted_schema = to_h.dup
      sorted_schema[:tournaments] = tournaments.map do |tournament|
        tournament.sort(*keys, direction: direction).to_h
      end

      # Return new Scoreboard with sorted data
      Scoreboard.new(
        event: @event_id,
        round: @round_id,
        tournament: @tournament_id,
        schema: sorted_schema
      )
    end

    private

    # Builds the complete scoreboard schema.
    #
    # This is where all the fetching, parsing, and assembly happens.
    # Called once and memoized.
    #
    # @return [Hash] the complete scoreboard schema
    #
    def build_schema
      resolve_round! unless @round_id
      resolve_tournaments! unless @tournament_ids

      # Fetch event and round for metadata
      event_obj = event
      round = fetch_round_metadata

      {
        meta: {
          event_id: @event_id,
          event_name: event_obj ? event_obj["name"] : @event_id.to_s,
          round_id: @round_id,
          round_name: round["name"],
        },
        tournaments: build_tournaments,
      }
    end

    # Returns the event object, fetching and memoizing it on first access.
    #
    # This avoids duplicate API calls when both resolve_round! and build_schema
    # need the event object.
    #
    # If skip_event_fetch was set to true, returns nil to avoid the expensive
    # paginated fetch operation.
    #
    # @return [GolfGenius::Event, nil] the event object or nil if skipped
    #
    def event
      return nil if @skip_event_fetch

      @event ||= GolfGenius::Event.fetch(@event_id)
    end

    # Returns the rounds list, fetching and memoizing it on first access.
    #
    # This avoids duplicate API calls when both resolve_round! and build_schema
    # need the rounds list.
    #
    # @return [Array<GolfGenius::Round>] array of rounds
    #
    def rounds
      @rounds ||= GolfGenius::Event.rounds(@event_id)
    end

    # Fetches round metadata.
    #
    # @return [Hash] the round hash with string keys
    #
    def fetch_round_metadata
      rounds_list = rounds
      # Normalize to string keys for consistency (API may return symbol or string keys)
      round = rounds_list.find { |r| r[:id].to_s == @round_id.to_s || r["id"].to_s == @round_id.to_s }
      normalize_keys(round)
    end

    # Normalizes hash keys to strings recursively.
    #
    # @param obj [Object] the object to normalize
    # @return [Object] the normalized object
    #
    def normalize_keys(obj)
      case obj
      when Hash
        obj.transform_keys(&:to_s).transform_values { |v| normalize_keys(v) }
      when Array
        obj.map { |v| normalize_keys(v) }
      else
        obj
      end
    end

    # Builds all tournaments.
    #
    # @return [Array<Hash>] array of tournament hashes
    #
    def build_tournaments
      @tournament_ids.map do |tournament_id|
        build_tournament(tournament_id)
      end
    end

    # Builds a single tournament structure.
    #
    # @param tournament_id [String] the tournament ID
    # @return [Hash] tournament hash with meta, columns, rows
    #
    def build_tournament(tournament_id)
      html_data, json_data = fetch_and_parse_tournament(tournament_id)
      merged_data = merge_tournament_data(html_data, json_data)
      column_structure = decompose_columns(html_data, json_data)
      rows = decompose_rows(merged_data, column_structure)

      build_tournament_hash(tournament_id, merged_data, column_structure, rows)
    end

    # Fetches and parses HTML and JSON for a tournament.
    #
    # @param tournament_id [String] the tournament ID
    # @return [Array<Hash, Hash>] array of [html_data, json_data]
    #
    def fetch_and_parse_tournament(tournament_id)
      # Fetch HTML and JSON
      html = GolfGenius::Event.tournament_results(@event_id, @round_id, tournament_id, format: :html)
      json_obj = GolfGenius::Event.tournament_results(@event_id, @round_id, tournament_id, format: :json)

      # Parse HTML
      html_parser = HtmlParser.new(html)
      html_data = html_parser.parse

      # Parse JSON
      json_string = json_obj.to_json(raw: true)
      json_parser = JsonParser.new(json_string)
      json_data = json_parser.parse

      [html_data, json_data]
    end

    # Merges HTML and JSON tournament data.
    #
    # @param html_data [Hash] parsed HTML data
    # @param json_data [Hash] parsed JSON data
    # @return [Hash] merged tournament data
    #
    def merge_tournament_data(html_data, json_data)
      merger = DataMerger.new(html_data, json_data, @round_id.to_i)
      merger.merge
    end

    # Decomposes columns into summary and round-specific sections.
    #
    # @param html_data [Hash] parsed HTML data
    # @param json_data [Hash] parsed JSON data
    # @return [Hash] column structure
    #
    def decompose_columns(html_data, json_data)
      decomposer = ColumnDecomposer.new(html_data[:columns], json_data[:rounds])
      decomposer.decompose
    end

    # Decomposes rows into structured format.
    #
    # @param merged_data [Hash] merged tournament data
    # @param column_structure [Hash] decomposed column structure
    # @return [Array<Hash>] array of decomposed rows
    #
    def decompose_rows(merged_data, column_structure)
      merged_data[:rows].map do |merged_row|
        decomposer = RowDecomposer.new(merged_row, column_structure)
        decomposer.decompose
      end
    end

    # Builds the final tournament hash structure.
    #
    # @param tournament_id [String] the tournament ID
    # @param merged_data [Hash] merged tournament data
    # @param column_structure [Hash] column structure
    # @param rows [Array<Hash>] decomposed rows
    # @return [Hash] tournament hash
    #
    def build_tournament_hash(tournament_id, merged_data, column_structure, rows)
      {
        meta: {
          tournament_id: tournament_id.to_i,
          name: merged_data[:tournament_meta][:name],
          cut_text: merged_data[:tournament_meta][:cut_text],
          adjusted: merged_data[:tournament_meta][:adjusted],
          rounds: merged_data[:tournament_meta][:rounds],
        },
        columns: column_structure,
        rows: rows,
      }
    end

    # Resolves the round_id if not explicitly provided.
    #
    # Uses memoized rounds list to find the latest round by index/date.
    #
    # @raise [StandardError] if no rounds exist for the event
    #
    def resolve_round!
      rounds_list = rounds

      raise StandardError, "No rounds found for event #{@event_id}" if rounds_list.nil? || rounds_list.empty?

      # Find latest round by index (primary), then date (fallback)
      # Same logic as Event#latest_round but uses memoized rounds
      latest = rounds_list.max_by do |round|
        [round[:index] || round["index"] || 0, round[:date] || round["date"] || ""]
      end

      @round_id = latest.id
    end

    # Resolves the tournament IDs if not explicitly provided.
    #
    # Fetches all tournaments for the event/round, filters out non-scoring tournaments,
    # and stores the list of tournament IDs.
    #
    # @raise [StandardError] if no scoring tournaments exist
    #
    def resolve_tournaments!
      all_tournaments = GolfGenius::Event.tournaments(@event_id, @round_id)

      if all_tournaments.nil? || all_tournaments.empty?
        raise StandardError, "No tournaments found for event #{@event_id}, round #{@round_id}"
      end

      # Filter out non-scoring tournaments (pairings, scorecard-printing, etc.)
      scoring_tournaments = all_tournaments.reject(&:non_scoring?)

      if scoring_tournaments.empty?
        raise StandardError, "No scoring tournaments found for event #{@event_id}, round #{@round_id}"
      end

      @tournament_ids = if @tournament_id
                          # If tournament_id was specified, filter to just that one
                          [@tournament_id]
                        else
                          # Store all scoring tournament IDs
                          scoring_tournaments.map(&:id)
                        end
    end
  end
end
