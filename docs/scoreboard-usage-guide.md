# Scoreboard Usage Guide

The `GolfGenius::Scoreboard` provides a clean, object-oriented interface for displaying tournament results in your application.

## Table of Contents

- [Quick Start](#quick-start)
- [Basic Usage](#basic-usage)
- [Rails View Examples](#rails-view-examples)
- [API Reference](#api-reference)
- [Advanced Usage](#advanced-usage)

## Quick Start

```ruby
# Create a scoreboard for an event (uses latest round by default)
scoreboard = GolfGenius::Scoreboard.new(event: "522157")

# Or specify a specific round
scoreboard = GolfGenius::Scoreboard.new(event: "522157", round: "1615931")

# Or filter to a specific tournament
scoreboard = GolfGenius::Scoreboard.new(
  event: "522157",
  round: "1615931",
  tournament: "4522280"
)

# Iterate tournaments → columns → rows → cells
scoreboard.tournaments.each do |tournament|
  puts tournament.name

  tournament.columns.each do |col|
    puts "  #{col.label}"
  end

  tournament.rows.each do |row|
    puts "#{row.name}:"
    row.cells.each do |cell|
      puts "  #{cell.column.label}: #{cell}"
    end
  end
end
```

## Basic Usage

### Accessing Tournaments

```ruby
# Get all tournaments
tournaments = scoreboard.tournaments
# => [Tournament, Tournament, ...]

# Find a specific tournament by ID
tournament = scoreboard.tournament(4522280)

# Find by name (exact match)
tournament = scoreboard.tournament("Overall Results")

# Find by partial name (case-insensitive)
tournament = scoreboard.tournament("overall")
# => finds "Overall Results"
```

### Tournament Properties

```ruby
tournament.id             # => 4522280
tournament.name           # => "Overall Results"
tournament.adjusted?      # => false

# Rounds (now a Rounds collection object)
tournament.rounds         # => #<Rounds size=4>
tournament.rounds.size    # => 4
tournament.rounds.current # => #<Round name="R2" playing?=true> or nil

# Access round metadata
tournament.rounds.each do |round|
  puts "#{round.name} - Round #{round.number}"
  puts "Playing: #{round.playing?}"
  puts "Complete: #{round.complete?}"
end

# Tournament metadata
tournament.cut_line_text  # => "The following players did not make the cut"
tournament.cut_players?   # => true
```

### Accessing Columns

Columns know which round they belong to (or nil for summary columns):

```ruby
# All columns (summary + rounds flattened)
tournament.columns.each do |col|
  round_info = col.round_name || "summary"
  puts "#{col.label} (#{col.format}, #{round_info})"
end
# => "Pos. (position, summary)"
# => "Player (player, summary)"
# => "Total To Par Gross (total-to-par-gross, summary)"
# => "Thru R2 (thru, R2)"
# => "To Par Gross R2 (to-par-gross, R2)"

# Filter to summary columns
summary_cols = tournament.columns.select { |c| c.round_id.nil? }
# => [Column(Pos.), Column(Player), Column(Total), ...]

# Filter to specific round
round_cols = tournament.columns.select { |c| c.round_id == 2001 }
# => [Column(Thru R2), Column(To Par Gross R2), ...]

# Group by round
tournament.columns.group_by(&:round_id).each do |round_id, cols|
  puts "Round #{round_id || 'Summary'}:"
  cols.each { |col| puts "  #{col.label}" }
end
```

### Column Properties

```ruby
col.key        # => :position (symbol, for accessing cell data)
col.format     # => "position" (string, for CSS classes)
col.label      # => "Pos." (string, for display)
col.index      # => 0 (integer, original column position)
col.round_id   # => 2001 or nil (integer or nil, which round this belongs to)
col.round_name # => "R2" or nil (string or nil, round name)
```

### Accessing Rows

```ruby
# Rows for a specific tournament
tournament.rows.each do |row|
  puts "#{row.name} - #{row.affiliation}"
end

# All rows across all tournaments
scoreboard.rows.each do |row|
  puts "#{row.name} (#{row.tournament_id})"
end
```

### Row Properties

```ruby
row.id            # => 2185971448
row.name          # => "Brian Lefferts"
row.player_ids    # => ["40208860"]
row.affiliation   # => "Tampa" (or ["City A", "City B"] for teams)
row.tournament_id # => 4522280
row.summary       # => { position: "1", player: "Brian Lefferts", ... }
row.rounds        # => { 2001 => { thru: "8", scorecard: {...} }, ... }

# Name parsing
row.first_name    # => "Brian"
row.last_name     # => "Lefferts"

# Affiliation parsing
row.affiliation_city   # => "Tampa"
row.affiliation_state  # => nil (or "OH" for "Columbus, OH")

# Position (direct access)
row.position      # => "1" (or "T2", "CUT", etc.)

# Status predicates
row.eliminated?   # => false (true if CUT, WD, DQ, NS, NC, MC)
row.cut?          # => false (true if position is "CUT" or "MC")
```

### Accessing Cells

Cells are objects that know their value and column:

```ruby
# Get all cells
row.cells.each do |cell|
  puts "#{cell.column.label}: #{cell.value}"
  puts "  Format: #{cell.column.format}"
  puts "  Round: #{cell.column.round_name || 'summary'}"
end

# Filter cells by round
summary_cells = row.cells.select { |c| c.column.round_id.nil? }
summary_cells.each do |cell|
  puts "#{cell.column.label}: #{cell}"
end

# Cells for a specific round
round_2_cells = row.cells.select { |c| c.column.round_id == 2001 }
round_2_cells.each do |cell|
  puts "#{cell.column.label}: #{cell}"
end
```

### Cell Properties

```ruby
cell.value   # => "1" or "+8" or "E" (the actual cell value)
cell.column  # => Column object (access to column metadata)
cell.to_s    # => "1" (string representation of value)
```

### Accessing Scorecard Data

```ruby
# Get round data (includes both HTML cells and JSON metadata)
round_data = row.rounds[2001] # Round R2

# HTML cell values
round_data[:thru]          # => "8"
round_data[:to_par_gross]  # => "-8"

# JSON metadata
scorecard = round_data[:scorecard]
scorecard[:status]         # => "partial"
scorecard[:gross_scores]   # => [4, 3, 3, 4, 2, 3, 3, 2, nil, ...]
scorecard[:to_par_gross]   # => [-1, -1, -1, -1, -1, -1, -1, -1, nil, ...]
scorecard[:totals]         # => { out: nil, in: nil, total: nil }
```

## Rails View Examples

### Simple Scoreboard Table

```erb
<%# app/views/tournaments/_scoreboard.html.erb %>

<% scoreboard = GolfGenius::Scoreboard.new(event: @event.id) %>

<% scoreboard.tournaments.each do |tournament| %>
  <div class="tournament">
    <h2><%= tournament.name %></h2>

    <% if tournament.cut_text %>
      <p class="cut-notice"><%= tournament.cut_text %></p>
    <% end %>

    <table class="scoreboard-table">
      <thead>
        <tr>
          <% tournament.columns.each do |col| %>
            <th class="col-<%= col.format %>"><%= col.label %></th>
          <% end %>
        </tr>
      </thead>

      <tbody>
        <% tournament.rows.each do |row| %>
          <tr class="<%= 'player-cut' if row.cut? %>">
            <% row.cells.each do |cell| %>
              <td class="col-<%= cell.column.format %>">
                <%= cell %>
              </td>
            <% end %>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>
<% end %>
```

### Table with Type-Based Formatting

```erb
<%# app/views/tournaments/_scoreboard_with_types.html.erb %>

<% scoreboard = GolfGenius::Scoreboard.new(event: @event.id) %>

<% scoreboard.tournaments.each do |tournament| %>
  <table class="scoreboard-table">
    <thead>
      <tr>
        <% tournament.columns.each do |col| %>
          <% if col.position? || col.player? || col.to_par? %>
            <th class="col-<%= col.type %>"><%= col.label %></th>
          <% end %>
        <% end %>
      </tr>
    </thead>

    <tbody>
      <% tournament.rows.each do |row| %>
        <tr>
          <% row.cells.select { |c| c.column.position? || c.column.player? || c.column.to_par? }.each do |cell| %>
            <td class="col-<%= cell.column.type %>">
              <% if cell.column.to_par? %>
                <strong><%= cell %></strong>
              <% else %>
                <%= cell %>
              <% end %>
            </td>
          <% end %>
        </tr>
      <% end %>
    </tbody>
  </table>
<% end %>
```

### Table with Round-Specific Styling

```erb
<%# app/views/tournaments/_scoreboard_with_rounds.html.erb %>

<% scoreboard = GolfGenius::Scoreboard.new(event: @event.id) %>

<% scoreboard.tournaments.each do |tournament| %>
  <table class="scoreboard-table">
    <thead>
      <tr>
        <% tournament.columns.each do |col| %>
          <%
            css_classes = ["col-#{col.format}"]
            css_classes << "round-#{col.round_id}" if col.round?
            css_classes << "summary" if col.summary?
          %>
          <th class="<%= css_classes.join(' ') %>">
            <%= col.label %>
          </th>
        <% end %>
      </tr>
    </thead>

    <tbody>
      <% tournament.rows.each do |row| %>
        <tr>
          <% row.cells.each do |cell| %>
            <%
              css_classes = ["col-#{cell.column.format}"]
              css_classes << "round-#{cell.column.round_id}" if cell.column.round_id
            %>
            <td class="<%= css_classes.join(' ') %>">
              <%= cell %>
            </td>
          <% end %>
        </tr>
      <% end %>
    </tbody>
  </table>
<% end %>
```

### Player Detail View

```erb
<%# app/views/players/_scorecard.html.erb %>

<% scoreboard = GolfGenius::Scoreboard.new(event: @event.id) %>
<% tournament = scoreboard.tournament(@tournament_id) %>
<% player_row = tournament.rows.find { |r| r.id == @aggregate_id } %>

<div class="player-scorecard">
  <h3><%= player_row.name %></h3>
  <p class="affiliation"><%= player_row.affiliation %></p>

  <h4>Summary</h4>
  <dl>
    <% player_row.cells.select { |c| c.column.round_id.nil? }.each do |cell| %>
      <dt><%= cell.column.label %></dt>
      <dd><%= cell %></dd>
    <% end %>
  </dl>

  <% tournament.rounds.each do |round| %>
    <h4><%= round[:name] %></h4>

    <% round_data = player_row.rounds[round[:id]] %>
    <% if round_data %>
      <table class="hole-by-hole">
        <thead>
          <tr>
            <% 18.times do |i| %>
              <th><%= i + 1 %></th>
            <% end %>
          </tr>
        </thead>
        <tbody>
          <tr>
            <% round_data[:scorecard][:gross_scores].each do |score| %>
              <td><%= score || '-' %></td>
            <% end %>
          </tr>
        </tbody>
      </table>

      <p>Status: <%= round_data[:scorecard][:status] %></p>
      <p>
        Totals:
        Out <%= round_data[:scorecard][:totals][:out] || '-' %>,
        In <%= round_data[:scorecard][:totals][:in] || '-' %>,
        Total <%= round_data[:scorecard][:totals][:total] || '-' %>
      </p>
    <% end %>
  <% end %>
</div>
```

### Summary Board (All Tournaments)

```erb
<%# app/views/events/_summary_board.html.erb %>

<% scoreboard = GolfGenius::Scoreboard.new(event: @event.id) %>

<table class="summary-board">
  <thead>
    <tr>
      <th>Tournament</th>
      <th>Player</th>
      <th>Affiliation</th>
      <th>Score</th>
    </tr>
  </thead>
  <tbody>
    <% scoreboard.rows.each do |row| %>
      <% tournament = scoreboard.tournament(row.tournament_id) %>
      <tr>
        <td><%= tournament.name %></td>
        <td><%= row.name %></td>
        <td><%= row.affiliation %></td>
        <td><%= row.summary[:total_to_par_gross] %></td>
      </tr>
    <% end %>
  </tbody>
</table>
```

### Alphabetical Board

```erb
<%# app/views/tournaments/_alpha_board.html.erb %>

<% scoreboard = GolfGenius::Scoreboard.new(event: @event.id, tournament: @tournament_id) %>
<% alpha_board = scoreboard.sort(:last_name) %>
<% tournament = alpha_board.tournaments.first %>

<table class="alpha-board">
  <thead>
    <tr>
      <% tournament.columns.each do |col| %>
        <th><%= col.label %></th>
      <% end %>
    </tr>
  </thead>
  <tbody>
    <% tournament.rows.each do |row| %>
      <tr>
        <% row.cells.each do |cell| %>
          <td><%= cell %></td>
        <% end %>
      </tr>
    <% end %>
  </tbody>
</table>
```

## API Reference

### Scoreboard

#### Constructor
```ruby
GolfGenius::Scoreboard.new(event:, round: nil, tournament: nil)
```
- `event` - Event object or event ID (required)
- `round` - Round object or round ID (optional, defaults to latest)
- `tournament` - Tournament object or tournament ID (optional, fetches all if not specified)

#### Methods
- `to_h` → Hash - Returns raw schema as hash
- `tournaments` → Array<Tournament> - Returns all tournaments
- `tournament(id_or_name)` → Tournament - Finds tournament by ID or name
- `rows` → Array<Row> - Returns all rows across all tournaments
- `sort(*keys, direction: :asc)` → Scoreboard - Returns new Scoreboard with all tournaments sorted

#### Sorting Examples
```ruby
scoreboard.sort                              # Default: competing first, then by position
scoreboard.sort(:position)                   # By position only
scoreboard.sort(:last_name)                  # Alphabetical
scoreboard.sort(:competing, :last_name)      # Competing players first, then alphabetical
scoreboard.sort(:position, :last_name)       # Multi-key: position, then name
scoreboard.sort(:position, direction: :desc) # Worst to best
```

### Tournament

#### Properties
- `id` → Integer (alias: `tournament_id`)
- `name` → String
- `cut_text` → String|nil (deprecated, use `cut_line_text`)
- `cut_line_text` → String|nil - Cut text message
- `cut_players?` → Boolean - True if any players eliminated
- `adjusted?` → Boolean
- `rounds` → Rounds - Rounds collection object (see Rounds section below)

#### Methods
- `columns` → Array<Column> - Returns all columns (summary + rounds flattened)
- `rows` → Array<Row> - Returns all rows
- `sort(*keys, direction: :asc)` → Tournament - Returns new Tournament with sorted rows
- `to_h` → Hash - Returns raw tournament hash

### Rounds (Collection)

The `tournament.rounds` object is a Rounds collection (not a plain array).

#### Properties
- `size` → Integer - Number of rounds
- `current` → Round|nil - The round currently in progress (or nil)

#### Methods
- `each` → Enumerator - Iterate over rounds (includes Enumerable)
- `[]` → Round|nil - Access by index
- `to_h` → Array<Hash> - Convert all rounds to hashes

### Round

#### Properties
- `id` → Integer - Round ID
- `name` → String - Round name (e.g., "R1", "R2")
- `number` → Integer|nil - Round number extracted from name (1, 2, 3, etc.)
- `date` → Date|String - Round date
- `playing?` → Boolean - Whether round is currently being played
- `complete?` → Boolean - Whether round is complete

#### Methods
- `to_h` → Hash - Returns raw round hash

### Column

#### Properties
- `key` → Symbol - For accessing cell data (e.g., :position, :thru)
- `format` → String - For CSS classes (e.g., "position", "thru")
- `label` → String - For display (e.g., "Pos.", "Thru R2")
- `index` → Integer - Original column position
- `round_id` → Integer|nil - Round ID if round-scoped, nil for summary
- `round_name` → String|nil - Round name if round-scoped (e.g., "R2"), nil for summary
- `type` → Symbol - Column type (:position, :player, :to_par, :strokes, :thru, :other)

#### Predicate Methods
- `summary?` → Boolean - True if summary column (no round_id)
- `round?` → Boolean - True if round-specific column
- `position?` → Boolean - True if type is :position
- `player?` → Boolean - True if type is :player
- `to_par?` → Boolean - True if type is :to_par
- `strokes?` → Boolean - True if type is :strokes
- `thru?` → Boolean - True if type is :thru

#### Methods
- `to_h` → Hash - Returns raw column hash

### Cell

#### Properties
- `value` → String|Integer - The cell value
- `column` → Column - The column this cell belongs to

#### Delegated Methods (from Column)
- `type` → Symbol - Delegates to column.type
- `summary?` → Boolean - Delegates to column.summary?
- `round?` → Boolean - Delegates to column.round?
- `position?` → Boolean - Delegates to column.position?
- `player?` → Boolean - Delegates to column.player?
- `to_par?` → Boolean - Delegates to column.to_par?
- `strokes?` → Boolean - Delegates to column.strokes?
- `thru?` → Boolean - Delegates to column.thru?

#### Methods
- `to_s` → String - String representation of value
- `to_h` → Hash - Returns hash with value and column

### Row

#### Properties
- `id` → Integer - Aggregate ID
- `name` → String - Player/team name
- `first_name` → String - First name
- `last_name` → String - Last name
- `player_ids` → Array<String> - Player IDs
- `affiliation` → String|Array<String>|nil - Raw affiliation
- `affiliation_city` → String|nil - City from affiliation
- `affiliation_state` → String|nil - State from affiliation (e.g., "OH")
- `position` → String - Position (e.g., "1", "T2", "CUT")
- `eliminated?` → Boolean - True if position is CUT, WD, DQ, NS, NC, MC
- `cut?` → Boolean - True if position is "CUT" or "MC"
- `tournament_id` → Integer
- `summary` → Hash - Summary cell data by column key
- `rounds` → Hash - Round data by round_id

#### Methods
- `cells` → Array<Cell> - All cells as Cell objects, matches `tournament.columns` order
- `to_h` → Hash - Returns raw row hash

## Advanced Usage

### Filtering Columns by Round

```ruby
# Get summary columns only
summary_cols = tournament.columns.select { |c| c.round_id.nil? }

# Get columns for a specific round
round_cols = tournament.columns.select { |c| c.round_id == 2001 }

# Group columns by round
by_round = tournament.columns.group_by(&:round_id)
# => { nil => [summaryand cols], 2001 => [round 2001 cols], 2000 => [round 2000 cols] }
```

### Filtering Cells by Round

```ruby
# Get summary cells only
summary_cells = row.cells.select { |c| c.column.round_id.nil? }

# Get cells for a specific round
round_cells = row.cells.select { |c| c.column.round_id == 2001 }

# Build a summary-only row
summary_cells.each do |cell|
  puts "#{cell.column.label}: #{cell}"
end
```

### Filtering and Sorting Rows

```ruby
# Filter by status
tournament.rows.reject(&:eliminated?)    # Only competing players
tournament.rows.select(&:cut?)           # Only cut players
tournament.rows.select(&:eliminated?)    # All eliminated players

# Filter by position (direct access)
tournament.rows.select { |r| r.position == "1" }
tournament.rows.select { |r| r.position.start_with?("T") }

# Sort by last name (NEW - built-in)
sorted = tournament.sort(:last_name)

# Sort by position (NEW - built-in)
sorted = tournament.sort(:position)

# Multi-key sort (NEW - position, then name for ties)
sorted = tournament.sort(:position, :last_name)

# Manual sorting still works if needed
tournament.rows.sort_by(&:name)
tournament.rows.sort_by { |r| r.last_name }
```

### Column Selection

```ruby
# Using type predicates (NEW - cleaner)
player_cols = tournament.columns.select(&:player?)
to_par_cols = tournament.columns.select(&:to_par?)
strokes_cols = tournament.columns.select(&:strokes?)

# Remove "thru" columns
columns = tournament.columns.reject(&:thru?)

# Get summary columns only
summary_cols = tournament.columns.select(&:summary?)

# Get round-specific columns
round_cols = tournament.columns.select(&:round?)

# Get columns for a specific round
r1_cols = tournament.columns.select { |c| c.round_id == 2001 }

# Old way still works (but predicates are cleaner)
columns = tournament.columns.select { |c| c.type == :position }
columns = tournament.columns.select { |c| ["position", "player"].include?(c.format) }
```

### Accessing Raw Schema

```ruby
# Get the complete schema as a hash (for JSON API, etc.)
schema = scoreboard.to_h

# Schema structure:
# {
#   meta: {
#     event_id: "522157",
#     event_name: "Event Name",
#     round_id: "1615931",
#     round_name: "R2"
#   },
#   tournaments: [
#     {
#       meta: { tournament_id, name, cut_text, adjusted, rounds },
#       columns: { summary: [...], rounds: [...] },
#       rows: [...]
#     }
#   ]
# }
```

### Converting Objects Back to Hashes

```ruby
# Tournament to hash
tournament_hash = tournament.to_h

# Row to hash
row_hash = row.to_h

# Column to hash
column_hash = col.to_h

# Cell to hash
cell_hash = cell.to_h
```

## Performance Tips

1. **Memoization** - The scoreboard memoizes the schema after first access. Subsequent calls to `to_h` or `tournaments` are cached.

2. **Filtering is non-mutating** - Methods like `filter`, `sort`, `select_columns` return new modified copies. The original schema is unchanged.

3. **Object creation** - Tournament/Row/Column/Cell objects are created lazily when first accessed and then cached.

4. **Use standard Ruby** - Since columns know their rounds and cells know their columns, you can use standard Ruby enumerable methods (`select`, `group_by`, `map`, etc.) instead of custom iterator methods.

## Error Handling

The Scoreboard fails hard on data inconsistencies:

```ruby
# Raises if no rounds exist
scoreboard = GolfGenius::Scoreboard.new(event: "999999")
# => StandardError: No rounds found for event 999999

# Raises if HTML and JSON data don't match
# => StandardError: HTML row 1001 has no matching JSON aggregate

# Raises if player IDs mismatch
# => StandardError: Player ID mismatch for aggregate 1001
```

This ensures data integrity and surfaces problems immediately rather than returning incomplete or incorrect results.
