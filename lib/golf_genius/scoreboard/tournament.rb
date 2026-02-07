# frozen_string_literal: true

require "date"

module GolfGenius
  class Scoreboard
    # Wraps a tournament hash to provide method-based access.
    #
    # A Tournament represents a single tournament within an event/round, including
    # its metadata (name, cut text, adjusted status), rounds, columns, and player rows.
    #
    # @example Accessing tournament data
    #   tournament = scoreboard.tournaments.first
    #   tournament.id           # => 4522280
    #   tournament.name         # => "Championship Flight"
    #   tournament.adjusted?    # => false
    #   tournament.rounds       # => [#<Round...>, #<Round...>]
    #   tournament.columns      # => [#<Column...>, #<Column...>]
    #   tournament.rows         # => [#<Row...>, #<Row...>]
    #
    class Tournament
      # @return [Hash] the raw tournament data hash
      attr_reader :data

      # Creates a new Tournament instance.
      #
      # @param data [Hash] the tournament data hash
      #
      def initialize(data)
        @data = data
      end

      # Returns the tournament ID.
      #
      # @return [Integer] the tournament ID
      #
      def id
        @data[:meta][:tournament_id]
      end

      alias tournament_id id

      # Returns the tournament name.
      #
      # @return [String] the tournament name (e.g., "Championship Flight")
      #
      def name
        @data[:meta][:name]
      end

      # Returns the cut text for players who didn't make the cut.
      #
      # @return [String, nil] cut text or nil if no cut
      #
      def cut_text
        @data[:meta][:cut_text]
      end

      # Returns whether the tournament has adjusted scores.
      #
      # @return [Boolean] true if adjusted, false otherwise
      #
      def adjusted?
        @data[:meta][:adjusted]
      end

      # Returns all rounds for this tournament as Round objects.
      #
      # The returned array has a custom +to_h+ method that converts all Round
      # objects to hashes for serialization.
      #
      # @return [Array<Round>] array of Round objects
      #
      # @example
      #   tournament.rounds.each do |round|
      #     puts "#{round.name}: #{round.date}"
      #   end
      #   tournament.rounds.to_h  # => [{id: 1, name: "R1", ...}, ...]
      #
      def rounds
        @rounds ||= begin
          rounds_array = @data[:meta][:rounds].map { |round| Round.new(round) }

          # Add to_h method to convert all Round objects to hashes
          # This allows tournament.rounds.to_h to return an array of round hashes
          # for serialization (e.g., to JSON)
          def rounds_array.to_h
            map(&:to_h)
          end

          rounds_array
        end
      end

      # Returns all columns for this tournament as Column objects.
      #
      # Combines summary columns (position, name, total, etc.) with round-specific
      # columns (R1, R2, etc.) in display order. The returned array has a custom
      # +to_h+ method for serialization.
      #
      # @return [Array<Column>] flat array of Column objects
      #
      # @example
      #   tournament.columns.each do |col|
      #     puts "#{col.label} (#{col.format})"
      #   end
      #   tournament.columns.to_h  # => [{key: "pos", label: "Pos", ...}, ...]
      #
      def columns
        @columns ||= begin
          summary_cols = @data[:columns][:summary].map { |col| Column.new(col) }
          round_cols = @data[:columns][:rounds].flat_map { |round| round[:columns].map { |col| Column.new(col) } }
          cols = summary_cols + round_cols

          # Add to_h method to convert all Column objects to hashes
          # This allows tournament.columns.to_h to return an array of column hashes
          # for serialization (e.g., to JSON)
          def cols.to_h
            map(&:to_h)
          end

          cols
        end
      end

      # Returns all player/team rows for this tournament as Row objects.
      #
      # @return [Array<Row>] array of Row objects representing players/teams
      #
      # @example
      #   tournament.rows.each do |row|
      #     puts "#{row.name}: #{row.cells.map(&:value).join(', ')}"
      #   end
      #
      def rows
        @rows ||= @data[:rows].map { |row| Row.new(row, self) }
      end

      # Returns the raw tournament data as a hash.
      #
      # @return [Hash] the underlying data hash
      #
      def to_h
        @data
      end
    end

    # Wraps a cell value with its column metadata.
    #
    # A Cell represents a single value in the tournament results table, paired
    # with the column it belongs to. This allows iteration over cells while
    # maintaining context about which column each value belongs to.
    #
    # @example Accessing cell data
    #   row.cells.each do |cell|
    #     puts "#{cell.column.label}: #{cell.value}"
    #     puts "Round: #{cell.column.round_name}" if cell.column.round_id
    #   end
    #
    class Cell
      # @return [Object] the cell value (String, Integer, nil, etc.)
      attr_reader :value

      # @return [Column] the column this cell belongs to
      attr_reader :column

      # Creates a new Cell instance.
      #
      # @param value [Object] the cell value
      # @param column [Column] the column object
      #
      def initialize(value, column)
        @value = value
        @column = column
      end

      # Returns the string representation of the cell value.
      #
      # @return [String] the value as a string
      #
      def to_s
        value.to_s
      end

      # Returns the cell as a hash with value and column data.
      #
      # @return [Hash] hash with :value and :column keys
      #
      def to_h
        {
          value: @value,
          column: @column.to_h,
        }
      end
    end

    # Wraps a column hash to provide method-based access to column metadata.
    #
    # A Column represents a single column in the tournament results table,
    # including its display label, format type, and optionally which round
    # it belongs to.
    #
    # @example Accessing column data
    #   col.label       # => "Pos"
    #   col.format      # => "position"
    #   col.round_id    # => nil (summary column)
    #   col.round_name  # => nil (summary column)
    #
    #   round_col.label      # => "R1"
    #   round_col.round_id   # => 1615930
    #   round_col.round_name # => "R1"
    #
    class Column
      # @return [Hash] the raw column data hash
      attr_reader :data

      # Creates a new Column instance.
      #
      # @param data [Hash] the column data hash
      #
      def initialize(data)
        @data = data
      end

      # Returns the column key used for data lookup.
      #
      # @return [Symbol] the column key (e.g., :position, :total, :score)
      #
      def key
        @data[:key]
      end

      # Returns the column format type.
      #
      # @return [String] format type (e.g., "position", "player-name", "round-total")
      #
      def format
        @data[:format]
      end

      # Returns the column display label.
      #
      # @return [String] the label shown in table headers (e.g., "Pos", "Player", "Total")
      #
      def label
        @data[:label]
      end

      # Returns the column index in the table.
      #
      # @return [Integer] zero-based column index
      #
      def index
        @data[:index]
      end

      # Returns the round ID if this is a round-specific column.
      #
      # @return [Integer, nil] round ID or nil for summary columns
      #
      def round_id
        @data[:round_id]
      end

      # Returns the round name if this is a round-specific column.
      #
      # @return [String, nil] round name (e.g., "R1", "R2") or nil for summary columns
      #
      def round_name
        @data[:round_name]
      end

      # Returns the raw column data as a hash.
      #
      # @return [Hash] the underlying data hash
      #
      def to_h
        @data
      end
    end

    # Wraps a round hash to provide method-based access to round metadata.
    #
    # A Round represents a single round of golf within a tournament, including
    # its date, name, and completion status. The date field is automatically
    # parsed from a string to a Date object for easier manipulation.
    #
    # @example Accessing round data
    #   round.id           # => 1615930
    #   round.name         # => "R1"
    #   round.date         # => #<Date: 2026-03-15>
    #   round.in_progress? # => false
    #   round.complete?    # => true
    #
    class Round
      # @return [Hash] the raw round data hash
      attr_reader :data

      # Creates a new Round instance.
      #
      # @param data [Hash] the round data hash
      #
      def initialize(data)
        @data = data
        parse_date!
      end

      # Returns the round ID.
      #
      # @return [Integer] the round ID
      #
      def id
        @data[:id]
      end

      # Returns the round name.
      #
      # @return [String] the round name (e.g., "R1", "R2", "R3")
      #
      def name
        @data[:name]
      end

      # Returns the round date.
      #
      # The date is automatically parsed from a string (e.g., "2026-03-15") to
      # a Date object. If parsing fails, the original string is returned.
      #
      # @return [Date, String] the round date as a Date object or original string
      #
      def date
        @data[:date]
      end

      # Returns the raw in_progress value.
      #
      # @return [Boolean, nil] true if in progress, false/nil otherwise
      #
      def in_progress
        @data[:in_progress]
      end

      # Returns whether the round is currently in progress.
      #
      # @return [Boolean] true if in progress, false otherwise
      #
      def in_progress?
        !!@data[:in_progress]
      end

      # Returns whether the round is complete.
      #
      # This is the inverse of {#in_progress?}.
      #
      # @return [Boolean] true if complete, false if in progress
      #
      def complete?
        !in_progress?
      end

      # Returns the raw round data as a hash.
      #
      # @return [Hash] the underlying data hash
      #
      def to_h
        @data
      end

      private

      # Parses the date string to a Date object.
      # If parsing fails, keeps the original string value.
      #
      # @return [void]
      #
      def parse_date!
        value = @data[:date]
        return unless value.is_a?(String) && !value.strip.empty?

        @data[:date] = Date.parse(value)
      rescue ArgumentError
        # Keep as string if parsing fails
        @data[:date] = value
      end
    end

    # Wraps a scorecard hash to provide method-based access to hole-by-hole scoring data.
    #
    # A Scorecard represents a player's detailed scoring information for a specific
    # round, including hole-by-hole scores, to-par values, completion status, and
    # totals for front nine, back nine, and overall.
    #
    # @example Accessing scorecard data
    #   scorecard = row.scorecard(round_id)
    #   scorecard.score          # => "72"
    #   scorecard.status         # => "complete"
    #   scorecard.thru           # => "18"
    #   scorecard.gross_scores   # => [4, 5, 3, 4, 2, 3, 3, 2, 4, ...]
    #   scorecard.to_par_gross   # => [-1, 0, -1, 0, -2, -1, -1, -2, -1, ...]
    #   scorecard.totals         # => { out: 36, in: 36, total: 72 }
    #
    # @example Iterating through all scorecards for a row
    #   row.scorecards.each do |scorecard|
    #     puts "Score: #{scorecard.score}, Status: #{scorecard.status}"
    #   end
    #
    class Scorecard
      # @return [Hash] the raw scorecard data hash
      attr_reader :data

      # Creates a new Scorecard instance.
      #
      # @param data [Hash] the scorecard data hash
      #
      def initialize(data)
        @data = data
      end

      # Returns the number of holes completed.
      #
      # @return [String, Integer] holes completed (e.g., "18", "8")
      #
      def thru
        @data[:thru]
      end

      # Returns the current score.
      #
      # @return [String, Integer] the score (e.g., "72", "E", "+2")
      #
      def score
        @data[:score]
      end

      # Returns the completion status.
      #
      # @return [String] status ("complete", "partial", "pending", etc.)
      #
      def status
        @data[:status]
      end

      # Returns the hole-by-hole gross scores.
      #
      # Array indices correspond to hole numbers (0 = hole 1, 1 = hole 2, etc.).
      # Unplayed holes are represented as nil.
      #
      # @return [Array<Integer, nil>] array of gross scores
      #
      # @example
      #   scorecard.gross_scores  # => [4, 5, 3, 4, 2, 3, 3, 2, 4, 5, 4, 3, 5, 4, 3, 4, 3, 4]
      #
      def gross_scores
        @data[:gross_scores] || []
      end

      # Returns the hole-by-hole net scores.
      #
      # Array indices correspond to hole numbers (0 = hole 1, 1 = hole 2, etc.).
      # Unplayed holes are represented as nil.
      #
      # @return [Array<Integer, nil>] array of net scores
      #
      def net_scores
        @data[:net_scores] || []
      end

      # Returns the hole-by-hole to-par values for gross scores.
      #
      # Array indices correspond to hole numbers (0 = hole 1, 1 = hole 2, etc.).
      # Values are relative to par (e.g., -1 = birdie, 0 = par, +1 = bogey).
      #
      # @return [Array<Integer, nil>] array of to-par values
      #
      # @example
      #   scorecard.to_par_gross  # => [-1, 0, -1, 0, -2, -1, -1, -2, -1, ...]
      #
      def to_par_gross
        @data[:to_par_gross] || []
      end

      # Returns the hole-by-hole to-par values for net scores.
      #
      # Array indices correspond to hole numbers (0 = hole 1, 1 = hole 2, etc.).
      # Values are relative to par (e.g., -1 = birdie, 0 = par, +1 = bogey).
      #
      # @return [Array<Integer, nil>] array of to-par values
      #
      def to_par_net
        @data[:to_par_net] || []
      end

      # Returns the totals for front nine, back nine, and overall.
      #
      # @return [Hash] hash with :out (front 9), :in (back 9), :total keys
      #
      # @example
      #   scorecard.totals  # => { out: 36, in: 36, total: 72 }
      #
      def totals
        @data[:totals] || {}
      end

      # Hash-like access to scorecard data.
      #
      # Provides backwards-compatible hash access for internal use
      # (e.g., in cell_value_for method).
      #
      # @param key [Symbol, String] the attribute key
      # @return [Object, nil] the attribute value
      #
      def [](key)
        @data[key.to_sym]
      end

      # Returns the raw scorecard data as a hash.
      #
      # @return [Hash] the underlying data hash
      #
      def to_h
        @data
      end
    end

    # Wraps a row hash to provide method-based access to player/team data.
    #
    # A Row represents a single player or team entry in the tournament results table,
    # including their identifying information, summary data, round-by-round scorecards,
    # and all table cell values.
    #
    # @example Accessing row data
    #   row.id           # => 12345
    #   row.name         # => "John Doe"
    #   row.player_ids   # => ["67890"]
    #   row.affiliation  # => "Country Club"
    #   row.cut?         # => false
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

      # Returns the affiliation (club, team, etc.).
      #
      # @return [String, Array<String>, nil] affiliation string, array for teams, or nil
      #
      def affiliation
        @data[:affiliation]
      end

      # Returns whether this row represents a player who missed the cut.
      #
      # @return [Boolean] true if cut, false otherwise
      #
      def cut?
        @data[:cut]
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
            Cell.new(value, col)
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

      private

      # Returns the cell value for a specific column.
      #
      # Looks up values from either the summary data (for summary columns)
      # or the round scorecard data (for round-specific columns).
      #
      # @param column [Column] the column object
      # @return [Object] the cell value
      #
      def cell_value_for(column)
        # Column keys are strings, but data hashes use symbol keys
        key = column.key.to_sym

        if column.round_id
          # Round-specific column: look up value in the round's scorecard
          rounds[column.round_id]&.[](key)
        else
          # Summary column: look up value in summary data
          summary[key]
        end
      end
    end
  end
end
