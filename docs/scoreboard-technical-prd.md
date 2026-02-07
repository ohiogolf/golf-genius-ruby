# Scoreboard Technical PRD

## Purpose

A standalone service object that normalizes Golf Genius tournament results into a semantic, round-aware table structure. The caller renders, filters, and sorts as needed. The Scoreboard eagerly fetches all tournaments for an event/round, parses HTML as the source of truth for table structure, and supplements with JSON metadata (hole-by-hole scores, scorecard statuses, cut positions, etc.).

## Goals

- Provide a stable, semantic table structure derived from HTML results.
- Organize data by tournament, with round-level decomposition within each.
- Merge JSON metadata directly into the structure (not kept separate).
- Offer minimal helper methods that do not impose presentation decisions.

## Non-Goals

- UI layout, styling, pagination, or auto-scrolling.
- Tournament-specific ranking logic or tie-break rules.
- Column selection logic for display (caller decides what to show).
- Merging players across tournaments (each tournament is self-contained).

## Architecture

### Standalone Service Object

The Scoreboard is NOT a `GolfGenius::Resource` subclass. It is a standalone service object that internally uses existing resources (`Event`, `Round`, `Tournament`, `TournamentResults`) to fetch and aggregate data. It lives at `GolfGenius::Scoreboard`.

### Eager Fetch

On construction, the Scoreboard eagerly fetches all tournaments for the given event/round. No lazy evaluation — everything is loaded upfront and memoized.

### Tournament Filtering

Non-scoring tournaments are filtered out automatically. Check if the API provides a tournament type field that explicitly marks pairings/scorecard-printing tournaments. If so, use that. Otherwise, fall back to case-insensitive substring matching on tournament name for patterns like "pairings" or "scorecard-printing". Only tournaments that represent actual scored results are included in the output.

## Inputs

```ruby
GolfGenius::Scoreboard.new(
  event: event,          # or event_id: "522157"
  round: round,          # or round_id: "1615931" (optional)
  tournament: tournament # or tournament_id: "4522280" (optional, filters to one)
)
```

Accept IDs or resource objects for `event`, `round`, and `tournament`.

## Defaulting Rules

- **Round**: If not specified, fetch `Event.rounds`, sort by `index` (ascending), and pick the latest (highest index). Fallback to sorting by `date` if index is not available. This means if R2 is in progress, you get R2 data — not R1's historical standings.
- **Tournament**: If not specified, fetch ALL tournaments for the event via `Event.tournaments`. For each tournament, call `Event.tournament_results(round_id:, tournament_id:, format:)` individually. Filter out non-scoring tournaments based on API-provided type/metadata (if available) or name-based heuristics (case-insensitive substring match for "pairings", "scorecard-printing"). If `tournament_id` is provided, fetch only that one tournament (still wrapped in the same `tournaments` array structure).

## Data Sources

### HTML (Source of Truth)

`Event.tournament_results(round_id:, tournament_id:, format: :html)` returns the HTML table that defines:
- Column structure (headers, order, semantic types via `data-format-text`)
- Row order (GG's ranking/positioning)
- Cell values (the displayed text)
- Row identity (`data-aggregate-id`, `data-member-ids`, `data-aggregate-name`)
- Affiliation (from `div.affiliation` inside player cells)
- Cut line separators (`tr.header` with `td.cut_list_tr`)

### JSON (Supplemental Metadata)

`Event.tournament_results(round_id:, tournament_id:, format: :json)` provides:
- `rounds` array with `id`, `name`, `date`, `in_progress` (contains ALL rounds in the tournament, not just the requested round)
- `adjusted` flag
- `scopes[].cut_list_position`
- Per-aggregate: `rounds[]` with `thru`, `score`, `total`, `scorecard_statuses` (array with per-member-card statuses)
- Per-aggregate: `gross_scores`, `net_scores`, `to_par_gross`, `to_par_net` (hole-by-hole for the fetched round — regardless of which round_id was passed, the API returns equivalent data)
- Per-aggregate: `previous_rounds_scores[]` with hole-by-hole for completed rounds (this contains historical round data, NOT including the current fetched round)
- Per-aggregate: `totals` with `out`, `in`, `total` breakdowns
- `column_visibility`, `column_names`

**Important**: The JSON response appears to return the same data structure regardless of which round_id is passed. The `rounds[]` array in the response contains all rounds, and the top-level `gross_scores`/`to_par_gross` arrays represent the fetched round's data.

JSON metadata is injected directly into the output structure wherever it makes sense (into round-level row data, into tournament meta, etc.) — it is NOT kept as a separate "json_metadata" section.

### Optional Context

- `Event.fetch` — event name, dates, archived status, ggid, season/category
- `Event.rounds` — round metadata (name, date, status, index)
- `Event.tournaments` — tournament name, scoring type, status, type

## Output Schema

### Top Level

```ruby
{
  meta: {
    event_id: "522157",
    event_name: "Leaderboard Testing Event",
    round_id: "1615931",
    round_name: "R2"
  },
  tournaments: [
    { meta: { ... }, columns: { ... }, rows: [ ... ] },
    { meta: { ... }, columns: { ... }, rows: [ ... ] },
    # ...
  ]
}
```

### Per-Tournament

Each tournament is fully self-contained with its own columns and rows. Different tournaments in the same event can have completely different column structures (stroke play vs skins vs match play).

```ruby
{
  meta: {
    tournament_id: 4522280,
    name: "Overall Results",
    cut_text: "The following players did not make match play",  # from HTML cut_list_tr, nil if no cut
    adjusted: false,
    rounds: [
      { id: 1615931, name: "R2", date: "2026-03-16", in_progress: true },
      { id: 1615930, name: "R1", date: "2026-03-15", in_progress: false }
    ]
  },
  columns: { ... },
  rows: [ ... ]
}
```

### Columns (Round-Decomposed)

Columns are split into `summary` (cumulative/identity columns) and `rounds` (per-round columns). This decomposition is derived by analyzing the HTML headers:

- **Summary columns**: Position, Player, Total To Par, Total Gross — columns that represent cumulative or identity data.
- **Round columns**: Thru R2, To Par Gross R2, R1 total, R2 total — columns scoped to a specific round.

How to assign columns to rounds from HTML:
1. `data-name` attribute on `<th>` (e.g., `data-name='R2'`)
2. Header text containing round names ("R1", "R2", etc.)
3. CSS class prefixes: `past_round_thru`, `past_round_to_par`, `past_round_total`
4. Columns without round indicators go into `summary`

```ruby
columns: {
  summary: [
    { key: "position",           format: "position",           label: "Pos." },
    { key: "player",             format: "player",             label: "Player" },
    { key: "total_to_par_gross", format: "total-to-par-gross", label: "Total To Par Gross" },
    { key: "total_gross",        format: "total-gross",        label: "Total Gross" }
  ],
  rounds: [
    {
      id: 1615930,
      name: "R1",
      in_progress: false,
      columns: [
        { key: "total", format: "round-total", label: "R1" }
      ]
    },
    {
      id: 1615931,
      name: "R2",
      in_progress: true,
      columns: [
        { key: "thru",         format: "thru",        label: "Thru R2" },
        { key: "to_par_gross", format: "to-par-gross", label: "To Par Gross R2" },
        { key: "total",        format: "round-total",  label: "R2" }
      ]
    }
  ]
}
```

#### Column Key and Format Rules

- **`format`**: The raw `data-format-text` value from the HTML `<th>` when present. When absent, use a synthetic format value:
  - `<th class='pos'>` with no `data-format-text` → format: `"position"`
  - `<th class='past_round_total'>` with header "R1" → format: `"round-total"`
  - `<th class='past_round_thru'>` → format: `"thru"` (usually has `data-format-text` already)
- **`key`**: Snake_case identifier derived from `format`. Within a round's columns, keys are local (just `"total"`, not `"r1_total"`). Within summary, keys are unique across the summary scope.
- **`label`**: The header text from the HTML, with `<br/>` tags converted to spaces.

### Rows

Each row represents a player (or team). Row identity and metadata are top-level fields. Cell values are split into `summary` and `rounds` matching the column structure.

```ruby
{
  id: 2185971448,                    # from data-aggregate-id (integer)
  name: "Brian Lefferts",            # from data-aggregate-name (string)
  player_ids: ["40208860"],          # from data-member-ids (string array, matches JSON format)
  affiliation: "Tampa",              # from div.affiliation in HTML (string, array if multiple, nil if none)
  cut: false,                        # true if this row appears after the cut line in HTML

  # Cumulative / identity cells (keyed by summary column keys)
  summary: {
    position: "1",
    total_to_par_gross: "+8",
    total_gross: "88"
  },

  # Per-round cells (keyed by round id, then by that round's column keys)
  rounds: {
    1615930 => {
      # HTML-derived cells (from columns)
      total: "88",

      # JSON-supplemented metadata nested under 'scorecard'
      scorecard: {
        thru: "F",
        score: "+16",
        status: "completed",              # collapsed from scorecard_statuses array (take first, or ensure all match)
        gross_scores: [4, 5, 3, 7, 6, 5, 6, 4, 7, 3, 5, 3, 7, 5, 3, 5, 3, 7],
        net_scores:   [4, 5, 3, 7, 6, 5, 6, 4, 7, 3, 5, 3, 7, 5, 3, 5, 3, 7],
        to_par_gross: [-1, 1, -1, 2, 3, 1, 2, 1, 3, -1, 2, -1, 2, 2, -1, 1, -2, 3],
        to_par_net:   [-1, 1, -1, 2, 3, 1, 2, 1, 3, -1, 2, -1, 2, 2, -1, 1, -2, 3],
        totals: { out: 47, in: 41, total: 88 }
      }
    },
    1615931 => {
      # HTML-derived cells (from columns)
      thru: "8",
      to_par_gross: "-8",              # HTML cell value (string)
      total: "-",

      # JSON-supplemented metadata nested under 'scorecard'
      scorecard: {
        score: "-8",
        status: "partial",
        gross_scores: [4, 3, 3, 4, 2, 3, 3, 2, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        net_scores:   [4, 3, 3, 4, 2, 3, 3, 2, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        to_par_gross: [-1, -1, -1, -1, -1, -1, -1, -1, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],  # array
        totals: { out: nil, in: nil, total: nil }
      }
    }
  }
}
```

**Naming Collision Resolution**: HTML cell values (strings like "8", "-8", "E") appear at the top level of the round hash, keyed by column key (e.g., `thru`, `to_par_gross`, `total`). JSON hole-by-hole metadata (arrays, status, totals) is nested under a `scorecard` sub-hash to avoid collisions and provide clear namespacing.

### Cut Lines

Cut lines are NOT represented as special separator rows. Instead:
- Each row has a `cut: true/false` field indicating whether the player is below the cut.
- The cut line text (e.g., "The following players did not make match play") is extracted from the HTML `<td class='cut_list_tr'>` element and stored in `tournament.meta.cut_text`. This is presentational text, not authoritative data.
- The `cut_list_position` field from the JSON is no longer used (legacy field, originally indicated row index of the cut boundary, but not needed in our output structure).
- In HTML, cut rows appear after a `<tr class='header'><td class='cut_list_tr'>...</td></tr>` element. All `aggregate-row` elements after this marker get `cut: true`. Rows with `pos` value of "CUT" are also marked as below the cut.

## Complete Examples

### Multi-Round Stroke Play (R2 In Progress)

This is the test event (`leaderboard-testing-event-522157`) fetched for round 1615931 (R2).

```ruby
{
  meta: {
    event_id: "522157",
    event_name: "Leaderboard Testing Event",
    round_id: "1615931",
    round_name: "R2"
  },
  tournaments: [
    {
      meta: {
        tournament_id: 4522280,
        name: "Overall Results",
        cut_text: nil,
        adjusted: false,
        rounds: [
          { id: 1615931, name: "R2", date: "2026-03-16", in_progress: true },
          { id: 1615930, name: "R1", date: "2026-03-15", in_progress: false }
        ]
      },
      columns: {
        summary: [
          { key: "position",           format: "position",           label: "Pos." },
          { key: "player",             format: "player",             label: "Player" },
          { key: "total_to_par_gross", format: "total-to-par-gross", label: "Total To Par Gross" },
          { key: "total_gross",        format: "total-gross",        label: "Total Gross" }
        ],
        rounds: [
          {
            id: 1615930, name: "R1", in_progress: false,
            columns: [
              { key: "total", format: "round-total", label: "R1" }
            ]
          },
          {
            id: 1615931, name: "R2", in_progress: true,
            columns: [
              { key: "thru",         format: "thru",        label: "Thru R2" },
              { key: "to_par_gross", format: "to-par-gross", label: "To Par Gross R2" },
              { key: "total",        format: "round-total",  label: "R2" }
            ]
          }
        ]
      },
      rows: [
        {
          id: 2185971448,
          name: "Brian Lefferts",
          player_ids: ["40208860"],
          affiliation: "Tampa",
          cut: false,
          summary: {
            position: "1",
            total_to_par_gross: "+8",
            total_gross: "88"
          },
          rounds: {
            1615930 => {
              total: "88",
              scorecard: {
                thru: "F",
                score: "+16",
                status: "completed",
                gross_scores: [4, 5, 3, 7, 6, 5, 6, 4, 7, 3, 5, 3, 7, 5, 3, 5, 3, 7],
                to_par_gross: [-1, 1, -1, 2, 3, 1, 2, 1, 3, -1, 2, -1, 2, 2, -1, 1, -2, 3],
                totals: { out: 47, in: 41, total: 88 }
              }
            },
            1615931 => {
              thru: "8",
              to_par_gross: "-8",
              total: "-",
              scorecard: {
                score: "-8",
                status: "partial",
                gross_scores: [4, 3, 3, 4, 2, 3, 3, 2, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
                to_par_gross: [-1, -1, -1, -1, -1, -1, -1, -1, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
                totals: { out: nil, in: nil, total: nil }
              }
            }
          }
        },
        {
          id: 2185971449,
          name: "Jason Comer",
          player_ids: ["40208864"],
          affiliation: "Columbus",
          cut: false,
          summary: {
            position: "2",
            total_to_par_gross: "+16",
            total_gross: "88"
          },
          rounds: {
            1615930 => {
              total: "88",
              scorecard: {
                thru: "F",
                score: "+16",
                status: "completed",
                gross_scores: [4, 3, 3, 6, 5, 3, 7, 5, 7, 6, 5, 7, 5, 3, 6, 4, 4, 5],
                to_par_gross: [-1, -1, -1, 1, 2, -1, 3, 2, 3, 2, 2, 3, 0, 0, 2, 0, -1, 1],
                totals: { out: 43, in: 45, total: 88 }
              }
            },
            1615931 => {
              thru: "9",
              to_par_gross: "E",
              total: "-",
              scorecard: {
                score: "E",
                status: "partial",
                gross_scores: [5, 5, 5, 4, 4, 4, 3, 3, 3, nil, nil, nil, nil, nil, nil, nil, nil, nil],
                to_par_gross: [0, 1, 1, -1, 1, 0, -1, 0, -1, nil, nil, nil, nil, nil, nil, nil, nil, nil],
                totals: { out: 36, in: nil, total: nil }
              }
            }
          }
        }
        # ... more rows
      ]
    },
    {
      meta: {
        tournament_id: 4522284,
        name: "16-18 Results - 16-18",
        # ... different tournaments can have different column structures
      },
      columns: { ... },
      rows: [ ... ]
    },
    {
      meta: {
        tournament_id: 4522288,
        name: "15 & Under Results - 15 & Under",
        # ...
      },
      columns: { ... },
      rows: [ ... ]
    }
  ]
}
```

### Single-Round Stroke Play

For a single-round event or fetching R1 before R2 starts, there is one round entry. Summary columns may be minimal since there's no multi-round aggregation. The HTML typically shows just: Pos, Player, Score, Total.

```ruby
{
  meta: { event_id: "522157", round_id: "1615930", round_name: "R1" },
  tournaments: [
    {
      meta: { tournament_id: 4522288, name: "15 & Under Results", rounds: [
        { id: 1615930, name: "R1", in_progress: false }
      ]},
      columns: {
        summary: [
          { key: "position", format: "position", label: "Pos." },
          { key: "player",   format: "player",   label: "Player" },
          { key: "total_to_par_gross", format: "total-to-par-gross", label: "Total To Par Gross" }
        ],
        rounds: [
          {
            id: 1615930, name: "R1", in_progress: false,
            columns: []  # no round-specific columns in single-round HTML
          }
        ]
      },
      rows: [
        {
          id: 2185971384,
          name: "Matt Lefferts",
          player_ids: ["40208863"],
          affiliation: "Dublin",
          cut: false,
          summary: {
            position: "1",
            total_to_par_gross: "+15"
          },
          rounds: {
            1615930 => {
              # no HTML round columns in single-round format
              # JSON supplements go under scorecard
              scorecard: {
                thru: "F",
                score: "+15",
                status: "completed",
                gross_scores: [7, 3, 3, 6, 7, 7, 4, 6, 3, 7, 7, 4, 4, 3, 3, 5, 4, 4],
                to_par_gross: [2, -1, -1, 1, 4, 3, 0, 3, -1, 3, 4, 0, -1, 0, -1, 1, -1, 0],
                totals: { out: 46, in: 41, total: 87 }
              }
            }
          }
        }
      ]
    }
  ]
}
```

### Team Skins (Non-Stroke-Play)

No round decomposition needed. Everything lives in `summary`. `rounds` is empty.

```ruby
{
  meta: { event_id: "...", round_id: "...", round_name: "R1" },
  tournaments: [
    {
      meta: { tournament_id: "...", name: "Skins Match", rounds: [...] },
      columns: {
        summary: [
          { key: "foursome", format: "foursome", label: "Foursome" },
          { key: "skins",    format: "skins",    label: "Skins" },
          { key: "purse",    format: "purse",    label: "Purse" },
          { key: "details",  format: "details",  label: "Details" }
        ],
        rounds: []
      },
      rows: [
        {
          id: 12345,
          name: "Smith / Jones / Brown / Davis",
          player_ids: ["111", "222", "333", "444"],
          affiliation: nil,
          cut: false,
          summary: {
            foursome: "Smith / Jones / Brown / Davis",
            skins: "3",
            purse: "$150.00",
            details: "3, 7, 12"
          },
          rounds: {}  # no round-specific data for skins
        }
      ]
    }
  ]
}
```

### Stroke Play with Cut Line

```ruby
{
  meta: { ... },
  tournaments: [
    {
      meta: {
        tournament_id: "...",
        name: "Championship Flight",
        cut_text: "The following players did not make match play"
      },
      columns: { ... },
      rows: [
        # Players above the cut
        { id: 1, name: "Leader", cut: false, summary: { position: "1", ... }, ... },
        { id: 2, name: "Second", cut: false, summary: { position: "2", ... }, ... },
        # ...
        # Players below the cut
        { id: 17, name: "Missed It", cut: true, summary: { position: "CUT", ... }, ... },
        { id: 18, name: "Also Missed", cut: true, summary: { position: "CUT", ... }, ... }
      ]
    }
  ]
}
```

## Convenience Accessors

The Scoreboard object should provide:

```ruby
scoreboard.tournaments                    # => Array of all tournament hashes
scoreboard.tournament(id)                 # => find by tournament_id
scoreboard.tournament("Overall Results")  # => find by name (fuzzy or exact TBD)
scoreboard.rows                           # => all rows across all tournaments, each
                                          #    decorated with tournament_id so caller
                                          #    knows origin (for the summary board use case)
```

## Helper Methods (Minimal)

These methods operate on the entire Scoreboard across all tournaments:

```ruby
scoreboard.filter(tournament_id:, field:, value:)        # filter rows in a specific tournament
scoreboard.reject_columns(tournament_id:, formats: [])   # remove columns from a specific tournament
scoreboard.select_columns(tournament_id:, formats: [])   # keep only specific columns in a tournament
scoreboard.sort(tournament_id:, field:, direction: :asc) # sort rows in a specific tournament
```

Notes:
- All helpers require a `tournament_id` to specify which tournament to operate on.
- `reject_columns` and `select_columns` operate on `format`, not `key`.
- `sort` should handle golf score normalization: `E` = 0, `+1` = 1, `-3` = -3, `T2` = 2, `CUT`/`WD`/`DQ` sort to bottom.
- All methods must use stable sorting to preserve order within tied positions.
- Provide score normalization helpers as standalone utilities.

## Downstream Use Cases

Two board types Matt from Ohio Golf wants:

1. **Alpha Board**: Per-tournament, players sorted alphabetically by last name. Used for posting/checking scores during a round.
2. **Summary Board**: All players across tournaments, sorted by final scores, showing top scores. Used for awards/results.

Both are caller concerns — the Scoreboard provides the data, the caller sorts/filters/renders.

## HTML Parsing Details

### Column Detection

From `<tr class='header thead'>`:
- Each `<th>` becomes a column
- `data-format-text` attribute provides the semantic format (e.g., `"player"`, `"to-par-gross"`)
- When `data-format-text` is absent, synthesize a format from CSS class:
  - `class='pos'` → `"position"`
  - `class='past_round_total'` → `"round-total"`
- `data-name` attribute indicates round scoping (e.g., `data-name='R2'`)
- `data-display-today` attribute marks live-round columns

### Round Assignment for Columns

A column belongs to a round if any of these apply:
1. Has `data-name='R2'` (or similar round name)
2. Header text matches a round name ("R1", "R2", etc.)
3. CSS class starts with `past_round_` (`past_round_thru`, `past_round_to_par`, `past_round_total`)

Columns without any round indicator go into `summary`.

### Row Detection

From `<tr class='aggregate-row'>`:
- `data-aggregate-id` → `row.id` (integer)
- `data-aggregate-name` → `row.name` (string)
- `data-member-ids` → `row.player_ids` (split on comma, keep as string array to match JSON format)
- `div.affiliation` inside the player cell → `row.affiliation` (array if multiple affiliations found in team rows, single string if only one, nil if none)
- `<td>` elements map to columns by index

### Cell Value Extraction

- Strip HTML tags, extract text content
- Remove hidden `<span>` elements (used for sorting in GG's UI)
- Trim whitespace
- The `div.score_to_print` class wraps the actual score value in some cells

### Cut Line Detection

- `<tr class='header'>` containing `<td class='cut_list_tr'>` marks the cut boundary
- Extract the text content for `meta.cut_text`
- All `aggregate-row` elements after this marker get `cut: true`

### Rows to Skip

- `<tr class='expanded hidden'>` — expandable detail rows (empty placeholders)
- `<tr style='height: 1px;'>` — spacer rows
- `<script>` blocks

## JSON Metadata Injection

Match JSON aggregates to HTML rows by `aggregate_id` (JSON `id` == HTML `data-aggregate-id`, both integers).

For each matched aggregate, inject into the corresponding round hash in the row under a `scorecard` namespace:

- From `aggregate.rounds[]` (matched by round id):
  - `thru`, `score`, `total`
  - `scorecard_statuses[]` → collapse to single `status` string (take first element's status, or ensure all match)
- From `aggregate.gross_scores`, `net_scores`, `to_par_gross`, `to_par_net`:
  - These are the FETCHED round's hole-by-hole data (the round we requested from the API)
  - Inject into the fetched round's `scorecard` hash
- From `aggregate.previous_rounds_scores[]` (matched by `round_id`):
  - Each entry contains a historical round's `gross_scores`, `net_scores`, `to_par_gross`, `to_par_net`, `totals`
  - Inject into the corresponding round's `scorecard` hash
- From `aggregate.totals`:
  - `out`, `in`, `total` breakdowns for the fetched round
  - `with_previous_rounds` contains cumulative totals (may not be needed if we're organizing by round)
  - Inject into the fetched round's `scorecard.totals`

All JSON metadata goes under `rounds[round_id][:scorecard]` to avoid naming collisions with HTML cell values.

## Column Format Vocabulary

Observed `data-format-text` values from HTML exports:

| Format | Meaning | Scope |
|--------|---------|-------|
| `player` | Player name | summary |
| `players` | Team/group name | summary |
| `to-par-gross` | Gross to-par (single round or overall) | round or summary |
| `to-par-net` | Net to-par | round or summary |
| `total` | Generic total | varies |
| `total-gross` | Gross total score | summary |
| `total-net` | Net total score | summary |
| `total-to-par-gross` | Cumulative gross to-par | summary |
| `total-to-par-net` | Cumulative net to-par | summary |
| `thru` | Holes completed in current round | round |
| `purse` | Payout amount | summary |
| `points` | Points total | summary |
| `stableford-points` | Stableford points | summary |
| `skins` | Skins count | summary |
| `match` | Match play status/score | summary |
| `foursome` | Foursome/team identifier | summary |
| `details` | Extra status text | summary |

Synthetic formats (no `data-format-text` in HTML):

| Format | Source | Meaning |
|--------|--------|---------|
| `position` | `<th class='pos'>` | Leaderboard position |
| `round-total` | `<th class='past_round_total'>` | Round total score |

## Implementation Notes

- Use Nokogiri for HTML parsing.
- Use lightweight internal `Column` and `Row` value objects (e.g., `Data.define`) for parsing.
- Keep the public schema as plain Ruby hashes (not custom objects).
- The Scoreboard class should be testable against the exported HTML/JSON files in `tmp/tournament_results/`.
- Use `player_ids` (matching gem resource naming), NOT `member_ids` (the raw API field name).
- Keep player IDs as strings (string arrays) to match JSON format and be consistent throughout.
- For `scorecard_statuses` array in JSON, collapse to a single `status` string by taking the first element's status value. If needed later, we can add validation to ensure all statuses match.

## Error Handling

Fail hard on all errors — do not degrade gracefully:

- If round is ambiguous (multiple rounds, none specified), raise `ArgumentError` with guidance.
- If HTML parsing fails, raise a parsing error with context.
- If HTML is empty but the API returns 200, raise an error rather than returning an empty table.
- If HTML parses successfully but JSON returns 404 (or vice versa), raise an error.
- If HTML and JSON have different player counts, raise an error.
- If a row in HTML has no matching aggregate in JSON, raise an error.
- If round data in JSON references a round_id that doesn't exist in `meta.rounds`, raise an error.
- If player_ids from HTML `data-member-ids` doesn't match JSON `member_ids_str`, raise an error.

The philosophy is: if data is inconsistent or missing, something is wrong — surface it immediately rather than guessing or hiding the problem.

## Key Design Decisions (Agreed)

1. **HTML is source of truth** for table structure; JSON supplements with metadata.
2. **Tournaments are first-class** — no merging across tournaments.
3. **Round-level decomposition** — columns and row cells are split into `summary` (cumulative) and per-`round` scopes.
4. **Cut lines are row metadata** (`cut: true`), not special separator rows. Cut text goes in tournament meta.
5. **Affiliation is row metadata**, not a cell or subtext. It's extracted from `div.affiliation` in the HTML.
6. **No CSS in output** — no colors, styles, or presentational data. Semantic metadata only.
7. **Eager fetch** — all data loaded on construction.
8. **API resource naming** — use `player_ids` not `member_ids`.
9. **Synthetic format values** for columns lacking `data-format-text`.
10. **JSON injected inline** — not kept as a separate metadata section.

## Test Data

The primary test dataset is in `tmp/tournament_results/leaderboard-testing-event-522157/`:
- 3 rounds: `1615930` (R1), `1615931` (R2), `1615932` (R3)
- 3 tournaments per round: Overall Results (`4522280`), 16-18 (`4522284`), 15 & Under (`4522288`)
- R1: All 7 players, single-round complete
- R2: All 7 players, R2 in-progress (thru 8/9/10), cumulative standings
- R3: Only R1 data visible, R3 not started

Additional reference datasets:
- `tmp/tournament_results/2025-us-open-final-qualifying-457827/` (multi-round qualifier)
- `tmp/tournament_results/2025-cdga-junior-championship-456862/` (multi-round, multiple tournaments)
- `tmp/tournament_results/2025-cdga-am-am-handicap-championship-458205/` (team net + purse)

## Resolved Questions

All initial questions have been resolved:

1. **Round ID resolution**: Fetch `Event.rounds`, sort by `index`, pick latest.
2. **JSON round data**: The API returns equivalent data regardless of which round_id is passed. The `rounds[]` array contains all rounds. Top-level hole-by-hole arrays represent the fetched round.
3. **Column key uniqueness**: Access pattern is `row[:summary][:key]` for summary columns and `row[:rounds][round_id][:key]` for round columns. No compound keys needed.
4. **Tournament filtering**: Check API-provided type field first, fall back to case-insensitive name substring matching.
5. **Fetching tournaments**: Call `Event.tournament_results(round_id:, tournament_id:, format:)` individually for each tournament.
6. **Affiliation parsing**: String if one affiliation, array if multiple (team rows), nil if none.
7. **Cut line metadata**: `cut_list_position` from JSON is no longer used. Only `cut_text` from HTML is kept.
8. **Non-stroke-play rounds**: `meta.rounds` still populated from JSON even if `columns.rounds` is empty.
9. **Scorecard status collapse**: Take first element's status from the `scorecard_statuses` array.
10. **Player IDs**: Keep as string arrays to match JSON format.
11. **Naming collision**: Nest JSON metadata under `scorecard` sub-hash to avoid collision with HTML cell values.
12. **Error handling**: Fail hard on all inconsistencies — no graceful degradation.
13. **Helper method scope**: All helpers take `tournament_id` as first parameter to specify which tournament to operate on.

## Remaining Open Questions

- **Cut line ties**: If the cut is top N and there's a tie at N, does GG include all tied players above the cut? Need to verify with real data.
- **"Overall Results" tournament**: Only exists in 3 of 47 examined events. No special handling — treat like any other tournament.
