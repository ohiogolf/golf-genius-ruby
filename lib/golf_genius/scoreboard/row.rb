# frozen_string_literal: true

require_relative "name_parser"
require_relative "affiliation_parser"

module GolfGenius
  class Scoreboard
    # Wraps a row hash to provide method-based access to player/team data.
    #
    # A Row represents a single player or team entry in the tournament results table,
    # including their identifying information, summary data, round-by-round scorecards,
    # and all table cell values.
    #
    # @example Accessing row data
    #   row.id           # => 12345
    #   row.name         # => "John Doe"
    #   row.first_name   # => "John"
    #   row.last_name    # => "Doe"
    #   row.full_name    # => "John Doe"
    #   row.player_ids   # => ["67890"]
    #   row.affiliation  # => "Country Club"
    #   row.position     # => "T2"
    #
    # @example Checking overall tournament status
    #   row.position     # => "CUT"
    #   row.cut?         # => true
    #   row.eliminated?  # => true
    #   row.competing?   # => false
    #
    #   row.position     # => "T2"
    #   row.competing?   # => true
    #   row.eliminated?  # => false
    #
    # @example Checking active round status
    #   row.playing?      # => true (player on course in current round)
    #   row.finished?     # => false
    #   row.not_started?  # => false
    #
    # @example Accessing scorecards
    #   row.rounds                    # => { 1615930 => #<Scorecard...>, ... }
    #   row.scorecard(1615930)        # => #<Scorecard...>
    #   row.scorecards                # => [#<Scorecard...>, #<Scorecard...>]
    #   row.scorecard(1615930).score  # => "72"
    #
    # @example Accessing cells
    #   row.cells.each do |cell|
    #     puts "#{cell.column.label}: #{cell.value}"
    #   end
    #
    class Row
      # Position values indicating a player missed the cut
      CUT_POSITIONS = %w[CUT MC].freeze

      # Position values indicating a player withdrew
      WITHDREW_POSITIONS = ["WD"].freeze

      # Position values indicating a player was disqualified
      DISQUALIFIED_POSITIONS = ["DQ"].freeze

      # Position values indicating a player did not show up
      NO_SHOW_POSITIONS = ["NS"].freeze

      # Position values indicating a player did not submit a scorecard
      NO_CARD_POSITIONS = ["NC"].freeze

      # All position values indicating a player is not competing
      ELIMINATED_POSITIONS = (
        CUT_POSITIONS +
        WITHDREW_POSITIONS +
        DISQUALIFIED_POSITIONS +
        NO_SHOW_POSITIONS +
        NO_CARD_POSITIONS
      ).freeze

      # @return [Hash] the raw row data hash
      attr_reader :data

      # @return [Tournament] the tournament this row belongs to
      attr_reader :tournament

      # Creates a new Row instance.
      #
      # @param data [Hash] the row data hash
      # @param tournament [Tournament] the parent tournament
      #
      def initialize(data, tournament)
        @data = data
        @tournament = tournament
      end

      # Returns the aggregate ID (player or team ID).
      #
      # @return [Integer] the aggregate ID
      #
      def id
        @data[:id]
      end

      # Returns the player or team name.
      #
      # @return [String] the name
      #
      def name
        @data[:name]
      end

      # Returns the full name (alias for name).
      #
      # @return [String] the full name
      #
      def full_name
        name
      end

      # Returns an array of Name objects representing the players.
      #
      # For individual players, returns a single-element array.
      # For teams, returns an array with one Name object per player.
      #
      # @return [Array<Name>] array of Name objects
      #
      # @example Individual player
      #   row.name  # => "John Doe"
      #   row.players.first.first_name  # => "John"
      #   row.players.first.last_name   # => "Doe"
      #
      # @example Team
      #   row.name  # => "John Doe + Jane Smith"
      #   row.players[0].first_name  # => "John"
      #   row.players[1].first_name  # => "Jane"
      #
      # @example With suffix and metadata
      #   row.name  # => "Paul Schlimm Jr. (a)"
      #   player = row.players.first
      #   player.first_name  # => "Paul"
      #   player.last_name   # => "Schlimm"
      #   player.suffix      # => "Jr."
      #   player.amateur?    # => true
      #
      def players
        return [] unless name

        # Parse names
        parsed_names = NameParser.parse(name)
        return [] unless parsed_names

        # Always work with arrays
        names_array = parsed_names.is_a?(Array) ? parsed_names : [parsed_names]

        # Parse affiliations (may be string, array, or nil)
        parsed_affiliations = parse_affiliations_for_players(names_array.length)

        # Attach affiliations to names
        names_array.each_with_index do |name_obj, index|
          name_obj.instance_variable_set(:@affiliation, parsed_affiliations[index])
        end

        names_array
      end

      # Returns the first name(s) parsed from the full name.
      #
      # For individual players, returns a single first name string.
      # For teams, returns an array of first names.
      #
      # @return [String, Array<String>, nil] first name(s) or nil if no name
      #
      # @example Individual player
      #   row.name        # => "John Doe"
      #   row.first_name  # => "John"
      #
      # @example Team
      #   row.name        # => "John Doe + Jane Smith"
      #   row.first_name  # => ["John", "Jane"]
      #
      # @example With suffix
      #   row.name        # => "Paul Schlimm Jr."
      #   row.first_name  # => "Paul"
      #
      def first_name
        return nil if players.empty?

        names = players.map(&:first_name)
        names.length == 1 ? names.first : names
      end

      # Returns the last name(s) parsed from the full name.
      #
      # For individual players, returns a single last name string.
      # For teams, returns an array of last names.
      #
      # @return [String, Array<String>, nil] last name(s) or nil if no name
      #
      # @example Individual player
      #   row.name       # => "John Doe"
      #   row.last_name  # => "Doe"
      #
      # @example Team
      #   row.name       # => "John Doe + Jane Smith"
      #   row.last_name  # => ["Doe", "Smith"]
      #
      # @example With suffix
      #   row.name       # => "Paul Schlimm Jr."
      #   row.last_name  # => "Schlimm"  # Note: suffix is separate, see row.players.first.suffix
      #
      def last_name
        return nil if players.empty?

        names = players.map(&:last_name)
        names.length == 1 ? names.first : names
      end

      # Returns the array of player IDs.
      #
      # For individual players, this is a single-element array.
      # For teams, this contains multiple player IDs.
      #
      # @return [Array<String>] array of player IDs
      #
      def player_ids
        @data[:player_ids]
      end

      # Returns the raw affiliation data (club, team, etc.).
      #
      # @return [String, Array<String>, nil] affiliation string, array for teams, or nil
      #
      def affiliation
        @data[:affiliation]
      end

      # Returns an array of Affiliation objects representing the player's/team's affiliations.
      #
      # For individual players, returns a single-element array.
      # For teams, returns an array with one Affiliation object per player.
      #
      # @return [Array<Affiliation>] array of Affiliation objects
      #
      # @example Individual player
      #   row.affiliation  # => "Columbus, OH"
      #   row.affiliations.first.city   # => "Columbus"
      #   row.affiliations.first.state  # => "OH"
      #
      # @example Team
      #   row.affiliation  # => ["Tampa", "Columbus, OH"]
      #   row.affiliations[0].city   # => "Tampa"
      #   row.affiliations[1].city   # => "Columbus"
      #   row.affiliations[1].state  # => "OH"
      #
      # @example Club name
      #   row.affiliation  # => "Scioto Country Club"
      #   row.affiliations.first.city   # => "Scioto Country Club"
      #   row.affiliations.first.state  # => nil
      #
      # @example Access via players
      #   row.players.first.affiliation  # => Affiliation object
      #
      def affiliations
        players.map(&:affiliation).compact
      end

      # Returns the full affiliation string(s).
      #
      # For individual players, returns a single string.
      # For teams, returns an array of strings.
      #
      # @return [String, Array<String>, nil] full affiliation(s) or nil if no affiliation
      #
      # @example Individual player
      #   row.affiliation       # => "Columbus, OH"
      #   row.affiliation_full  # => "Columbus, OH"
      #
      # @example Team
      #   row.affiliation       # => ["Tampa", "Columbus, OH"]
      #   row.affiliation_full  # => ["Tampa", "Columbus, OH"]
      #
      def affiliation_full
        return nil if affiliations.empty?

        fulls = affiliations.map(&:full)
        fulls.length == 1 ? fulls.first : fulls
      end

      # Returns the city/club name(s) parsed from the affiliation.
      #
      # For individual players, returns a single city string.
      # For teams, returns an array of city strings.
      #
      # @return [String, Array<String>, nil] city name(s) or nil if no affiliation
      #
      # @example Individual player with city/state
      #   row.affiliation       # => "Columbus, OH"
      #   row.affiliation_city  # => "Columbus"
      #
      # @example Individual player with club name
      #   row.affiliation       # => "Scioto Country Club"
      #   row.affiliation_city  # => "Scioto Country Club"
      #
      # @example Team
      #   row.affiliation       # => ["Tampa", "Columbus, OH"]
      #   row.affiliation_city  # => ["Tampa", "Columbus"]
      #
      def affiliation_city
        return nil if affiliations.empty?

        cities = affiliations.map(&:city)
        cities.length == 1 ? cities.first : cities
      end

      # Returns the state abbreviation(s) parsed from the affiliation.
      #
      # For individual players, returns a single state string or nil.
      # For teams, returns an array of state strings (with nil for affiliations without states).
      #
      # @return [String, Array<String>, nil] state abbreviation(s) or nil
      #
      # @example Individual player with city/state
      #   row.affiliation        # => "Columbus, OH"
      #   row.affiliation_state  # => "OH"
      #
      # @example Individual player with club name
      #   row.affiliation        # => "Scioto Country Club"
      #   row.affiliation_state  # => nil
      #
      # @example Team
      #   row.affiliation        # => ["Tampa", "Columbus, OH"]
      #   row.affiliation_state  # => [nil, "OH"]
      #
      def affiliation_state
        return nil if affiliations.empty?

        states = affiliations.map(&:state)
        states.length == 1 ? states.first : states
      end

      # Returns the player's position in the tournament.
      #
      # Position values can be numeric ("1", "2"), tied ("T2", "T15"),
      # or status indicators ("CUT", "WD", "DQ", "NS", "NC").
      #
      # @return [String, nil] the position value or nil if not found
      #
      # @example
      #   row.position  # => "T2"
      #   row.position  # => "CUT"
      #   row.position  # => "1"
      #
      def position
        pos_cell = cells.find { |cell| cell.column.format == "position" }
        pos_cell&.value
      end

      # Returns whether this row represents a player who missed the cut.
      #
      # Checks if the position value is "CUT" or "MC" (case-insensitive).
      #
      # @return [Boolean] true if cut, false otherwise
      #
      # @example
      #   row.position  # => "CUT"
      #   row.cut?      # => true
      #
      def cut?
        pos = position
        return false if pos.nil?

        CUT_POSITIONS.include?(pos.to_s.upcase)
      end

      # Returns whether this row represents a player who withdrew.
      #
      # Checks if the position value is "WD" (case-insensitive).
      #
      # @return [Boolean] true if withdrew, false otherwise
      #
      # @example
      #   row.position  # => "WD"
      #   row.withdrew? # => true
      #
      def withdrew?
        pos = position
        return false if pos.nil?

        WITHDREW_POSITIONS.include?(pos.to_s.upcase)
      end

      # Returns whether this row represents a player who was disqualified.
      #
      # Checks if the position value is "DQ" (case-insensitive).
      #
      # @return [Boolean] true if disqualified, false otherwise
      #
      # @example
      #   row.position      # => "DQ"
      #   row.disqualified? # => true
      #
      def disqualified?
        pos = position
        return false if pos.nil?

        DISQUALIFIED_POSITIONS.include?(pos.to_s.upcase)
      end

      # Returns whether this row represents a player who did not show up.
      #
      # Checks if the position value is "NS" (case-insensitive).
      #
      # @return [Boolean] true if no show, false otherwise
      #
      # @example
      #   row.position  # => "NS"
      #   row.no_show?  # => true
      #
      def no_show?
        pos = position
        return false if pos.nil?

        NO_SHOW_POSITIONS.include?(pos.to_s.upcase)
      end

      # Returns whether this row represents a player who did not submit a scorecard.
      #
      # Checks if the position value is "NC" (case-insensitive).
      #
      # @return [Boolean] true if no card, false otherwise
      #
      # @example
      #   row.position  # => "NC"
      #   row.no_card?  # => true
      #
      def no_card?
        pos = position
        return false if pos.nil?

        NO_CARD_POSITIONS.include?(pos.to_s.upcase)
      end

      # Returns whether this row represents a player who is not competing.
      #
      # A player is eliminated if they missed the cut, withdrew, were disqualified,
      # did not show up, or did not submit a scorecard.
      #
      # @return [Boolean] true if eliminated, false otherwise
      #
      # @example
      #   row.position    # => "CUT"
      #   row.eliminated? # => true
      #
      #   row.position    # => "WD"
      #   row.eliminated? # => true
      #
      #   row.position    # => "T2"
      #   row.eliminated? # => false
      #
      def eliminated?
        pos = position
        return false if pos.nil?

        ELIMINATED_POSITIONS.include?(pos.to_s.upcase)
      end

      # Returns whether this row represents a player who is still competing.
      #
      # A player is competing if they are not eliminated (not cut, withdrew,
      # disqualified, no show, or no card).
      #
      # @return [Boolean] true if competing, false otherwise
      #
      # @example
      #   row.position    # => "T2"
      #   row.competing?  # => true
      #
      #   row.position    # => "CUT"
      #   row.competing?  # => false
      #
      def competing?
        !eliminated?
      end

      # Returns whether this player is currently playing in the active round.
      #
      # Checks the player's scorecard for the currently playing round
      # (determined by tournament.rounds.find(&:playing?)).
      #
      # @return [Boolean] true if player is on course, false otherwise
      #
      # @example
      #   row.playing?  # => true (player is on course, thru = "8")
      #
      def playing?
        active_round = tournament.rounds.find(&:playing?)
        return false unless active_round

        scorecard(active_round.id)&.playing? || false
      end

      # Returns whether this player has finished the active round.
      #
      # Checks the player's scorecard for the currently playing round
      # (determined by tournament.rounds.find(&:playing?)).
      #
      # @return [Boolean] true if player finished, false otherwise
      #
      # @example
      #   row.finished?  # => true (player finished, thru = "F")
      #
      def finished?
        active_round = tournament.rounds.find(&:playing?)
        return false unless active_round

        scorecard(active_round.id)&.finished? || false
      end

      # Returns whether this player has not started the active round.
      #
      # Checks the player's scorecard for the currently playing round
      # (determined by tournament.rounds.find(&:playing?)).
      #
      # @return [Boolean] true if player hasn't teed off, false otherwise
      #
      # @example
      #   row.not_started?  # => true (player hasn't teed off yet)
      #
      def not_started?
        active_round = tournament.rounds.find(&:playing?)
        return false unless active_round

        scorecard(active_round.id)&.not_started? || false
      end

      # Returns the tournament ID.
      #
      # @return [Integer] the tournament ID
      #
      def tournament_id
        @data[:tournament_id]
      end

      # Returns the summary data hash.
      #
      # Contains values for summary columns (position, name, total, etc.).
      # This is primarily used internally for cell value lookup. For display
      # purposes, use {#cells} instead.
      #
      # @return [Hash] hash of column_key => value
      #
      def summary
        @data[:summary]
      end

      # Returns scorecards for each round, keyed by round_id.
      #
      # Each value is a Scorecard object with hole-by-hole data including
      # gross scores, net scores, to-par values, and totals.
      #
      # @return [Hash{Integer => Scorecard}] hash of round_id => Scorecard
      #
      # @example
      #   row.rounds[1615930]               # => #<Scorecard...>
      #   row.rounds[1615930].gross_scores  # => [4, 5, 3, ...]
      #
      def rounds
        @rounds ||= begin
          rounds_hash = {}
          @data[:rounds].each do |round_id, scorecard_data|
            rounds_hash[round_id] = Scorecard.new(scorecard_data)
          end
          rounds_hash
        end
      end

      # Returns the scorecard for a specific round.
      #
      # This is a convenience method for accessing scorecards by round ID.
      #
      # @param round_id [Integer, String] the round ID
      # @return [Scorecard, nil] the scorecard or nil if not found
      #
      # @example
      #   scorecard = row.scorecard(1615930)
      #   scorecard.score          # => "72"
      #   scorecard.gross_scores   # => [4, 5, 3, 4, 2, 3, 3, 2, 4, ...]
      #
      def scorecard(round_id)
        rounds[round_id.to_i]
      end

      # Returns all scorecards as an array.
      #
      # @return [Array<Scorecard>] array of Scorecard objects
      #
      # @example
      #   row.scorecards.each do |sc|
      #     puts "Score: #{sc.score}, Status: #{sc.status}"
      #   end
      #
      def scorecards
        rounds.values
      end

      # Returns all cells as Cell objects.
      #
      # Cells are returned in the same order as tournament.columns, with each
      # cell containing its value and column metadata. The returned array has
      # a custom +to_h+ method for serialization.
      #
      # @return [Array<Cell>] array of Cell objects matching tournament.columns order
      #
      # @example
      #   row.cells.each do |cell|
      #     puts "#{cell.column.label}: #{cell.value}"
      #   end
      #   row.cells.to_h  # => [{value: "1", column: {...}}, ...]
      #
      def cells
        @cells ||= begin
          cells_array = @tournament.columns.map do |col|
            value = cell_value_for(col)
            Cell.new(value, col, to_par: to_par_for(col, value))
          end

          # Add to_h method to convert all Cell objects to hashes
          # This allows row.cells.to_h to return an array of cell hashes
          # for serialization (e.g., to JSON)
          def cells_array.to_h
            map(&:to_h)
          end

          cells_array
        end
      end

      # Returns the raw row data as a hash.
      #
      # @return [Hash] the underlying data hash
      #
      def to_h
        @data
      end

      # Returns the round ID where the player was eliminated.
      #
      # For WD players, returns the round where they withdrew.
      # For CUT/DQ/etc, returns the last round they played.
      #
      # @return [Integer, nil] the round ID, or nil if not eliminated
      #
      # @example
      #   row.position             # => "WD"
      #   row.elimination_round_id # => 1615931 (R2)
      #
      def elimination_round_id
        return nil unless eliminated?

        # Find the last round with actual scorecard data
        played_rounds = @data[:rounds].select do |_round_id, round_data|
          round_data && round_data[:thru] && !round_data[:thru].to_s.strip.empty?
        end

        return nil if played_rounds.empty?

        # Return the round ID of the last played round
        played_rounds.keys.max
      end

      # Returns the Round object where the player was eliminated.
      #
      # @return [Round, nil] the elimination round, or nil if not eliminated
      #
      # @example
      #   row.elimination_round      # => #<Round name="R2">
      #   row.elimination_round.name # => "R2"
      #
      def elimination_round
        round_id = elimination_round_id
        return nil unless round_id

        tournament.rounds.find { |r| r.id == round_id }
      end

      private

      # Parses affiliations for the given number of players.
      #
      # @param player_count [Integer] number of players
      # @return [Array<Affiliation, nil>] array of Affiliation objects or nils
      #
      def parse_affiliations_for_players(player_count)
        return Array.new(player_count) unless affiliation

        if affiliation.is_a?(Array)
          # Team: parse each affiliation
          affiliation.map { |aff| AffiliationParser.parse(aff) }
        else
          # Individual: parse single affiliation
          [AffiliationParser.parse(affiliation)]
        end
      end

      # Returns the to-par value for a cell based on its column type.
      #
      # @param column [Column] the column object
      # @param value [Object] the cell's display value
      # @return [Integer, nil] the to-par value
      #
      def to_par_for(column, value)
        if column.to_par?
          parse_to_par(value)
        elsif column.strokes? && column.round?
          scorecard(column.round_id)&.total_to_par
        elsif column.strokes? && column.summary?
          summary_to_par
        end
      end

      # Parses a to-par display string into an integer.
      #
      # @param value [Object] the to-par string (e.g., "-4", "+10", "E")
      # @return [Integer, nil] parsed value or nil
      #
      def parse_to_par(value)
        return nil if value.nil?

        str = value.to_s.strip
        return nil if str.empty?
        return 0 if str.upcase == "E"

        Integer(str)
      rescue ArgumentError
        nil
      end

      # Returns the total to-par across all played rounds.
      #
      # @return [Integer, nil] summed to-par or nil if no data
      #
      def summary_to_par
        values = scorecards.filter_map(&:total_to_par)
        return nil if values.empty?

        values.sum
      end

      # Returns the cell value for a specific column.
      #
      # Looks up values from either the summary data (for summary columns)
      # or the round scorecard data (for round-specific columns).
      #
      # For round-specific columns, returns nil if the player did not play
      # that round (to avoid showing incorrect data for unplayed rounds).
      #
      # For WD players, all unplayed rounds show "WD" to match tournament convention.
      #
      # @param column [Column] the column object
      # @return [Object] the cell value, or nil for unplayed rounds
      #
      def cell_value_for(column)
        # Column keys are strings, but data hashes use symbol keys
        key = column.key.to_sym

        if column.round_id
          # Round-specific column: look up value in the round's scorecard
          scorecard = rounds[column.round_id]
          return nil unless scorecard

          # Special handling for WD players in strokes columns
          # Use raw position to avoid circular dependency (position → cells → cell_value_for)
          return wd_round_strokes_value(column.round_id) if withdrew_raw? && column.strokes?

          # Get the value first
          value = scorecard[key]

          # If we have actual data, return it immediately (this handles completed
          # historical rounds that may have data but empty thru/status fields)
          return value unless value.nil? || value.to_s.strip.empty?

          # If no data and round hasn't started, return nil
          return nil if scorecard.not_started?

          # Otherwise return the value as-is for started rounds (handles in-progress
          # rounds where a field might legitimately be empty but round has started)
          value
        else
          # Summary column: look up value in summary data
          # Special handling for WD players (use raw to avoid circular dependency)
          if withdrew_raw?
            return nil if column.to_par?   # Show "-" for to-par
            return "WD" if column.strokes? # Show "WD" for strokes
          end

          summary[key]
        end
      end

      # Returns strokes value for WD players in a specific round.
      #
      # Shows the numeric score for completed rounds, "WD" for the round
      # where they actually withdrew (has hole-by-hole data), and nil for
      # rounds they never played.
      #
      # @param round_id [Integer] the round ID
      # @return [String, Integer, nil] score, "WD", or nil
      #
      def wd_round_strokes_value(round_id)
        round_data = @data[:rounds][round_id]
        return nil unless round_data

        total = round_data[:total]

        # Completed round with a numeric score (e.g., R1 = 74)
        return total if total && !total.to_s.strip.empty? && total.to_s.match?(/^\d+$/)

        # Distinguish the actual withdrawal round (player was on the course)
        # from post-WD rounds (player never played). The withdrawal round
        # will have hole-by-hole scorecard data.
        scorecard_data = round_data[:scorecard]
        return unless scorecard_data &&
                      scorecard_data[:gross_scores]&.any? { |s| !s.nil? }

        "WD"
      end

      # Returns position directly from raw data to avoid circular dependency.
      #
      # Cannot call the position method here because:
      # position → cells → cell_value_for → withdrew? → position (infinite loop!)
      #
      # @return [String, nil] the position value
      #
      def raw_position
        @data[:summary][:position]
      end

      # Checks if player withdrew (WD status) using raw data.
      #
      # Avoids circular dependency by accessing position directly from @data.
      #
      # @return [Boolean] true if withdrew
      #
      def withdrew_raw?
        pos = raw_position
        return false if pos.nil?

        pos.to_s.upcase == "WD"
      end
    end
  end
end
