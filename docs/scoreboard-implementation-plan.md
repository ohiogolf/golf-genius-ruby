# Scoreboard Implementation Plan

## Overview

This document breaks down the implementation of `GolfGenius::Scoreboard` into discrete, testable steps. Each step builds on the previous ones and can be verified independently.

## Phase 1: Foundation & Setup

### Step 1.1: Create Base Class Structure
**File**: `lib/golf_genius/scoreboard.rb`

- [ ] Create `GolfGenius::Scoreboard` class
- [ ] Define initializer accepting `event:`, `event_id:`, `round:`, `round_id:`, `tournament:`, `tournament_id:`
- [ ] Add parameter validation (require event, optional round/tournament)
- [ ] Add basic attr_readers for configuration
- [ ] Create empty `to_h` method that will return the final schema

**Test**: Instantiation works with various parameter combinations.

### Step 1.2: Implement Round Resolution
**File**: `lib/golf_genius/scoreboard.rb`

- [ ] Fetch `Event.rounds` if round not specified
- [ ] Sort rounds by `index` (fallback to `date`)
- [ ] Select latest round
- [ ] Store resolved round_id and round object

**Test**:
- Given event with multiple rounds, selects latest
- Given explicit round, uses that round
- Raises error if no rounds exist

### Step 1.3: Implement Tournament Resolution
**File**: `lib/golf_genius/scoreboard.rb`

- [ ] Fetch `Event.tournaments` if tournament not specified
- [ ] Filter out non-scoring tournaments (check API type field or name patterns)
- [ ] Store resolved tournament list (array of tournament IDs)
- [ ] Handle single tournament case (when tournament_id specified)

**Test**:
- Given event with multiple tournaments, returns all scoring tournaments
- Filters out tournaments with "pairings" or "scorecard-printing" in name
- Given explicit tournament_id, returns only that tournament
- Raises error if no scoring tournaments exist

## Phase 2: HTML Parsing

### Step 2.1: Create HTML Parser Value Objects
**Files**: `lib/golf_genius/scoreboard/column.rb`, `lib/golf_genius/scoreboard/round_info.rb`

- [ ] Create `Column` data class (using `Data.define` or similar)
  - Fields: `key`, `format`, `label`, `round_id`, `scope` (`:summary` or `:round`)
- [ ] Create `RoundInfo` data class
  - Fields: `id`, `name`, `in_progress`

**Test**: Value objects can be instantiated and accessed.

### Step 2.2: Parse Column Headers
**File**: `lib/golf_genius/scoreboard/html_parser.rb`

- [ ] Create `HTMLParser` class
- [ ] Implement `parse_columns(html_doc)` method
- [ ] Extract `<tr class='header thead'>` headers
- [ ] For each `<th>`:
  - Extract `data-format-text` (or synthesize from CSS class)
  - Extract label (convert `<br/>` to spaces)
  - Detect round assignment (via `data-name`, header text, CSS class patterns)
  - Generate snake_case key from format
- [ ] Return array of `Column` objects

**Test**:
- Parses multi-round HTML correctly (R1, R2 columns separated)
- Synthesizes format for columns without `data-format-text`
- Correctly identifies summary vs round-scoped columns
- Handles single-round HTML

### Step 2.3: Parse Row Data
**File**: `lib/golf_genius/scoreboard/html_parser.rb`

- [ ] Implement `parse_rows(html_doc, columns)` method
- [ ] Extract all `<tr class='aggregate-row'>` elements
- [ ] For each row, extract:
  - `data-aggregate-id` → `id` (integer)
  - `data-aggregate-name` → `name`
  - `data-member-ids` → `player_ids` (string array)
  - `div.affiliation` → `affiliation` (string, array, or nil)
  - `cut` status (true if after cut marker)
- [ ] Extract cell values mapped to columns by index
- [ ] Return array of row hashes

**Test**:
- Extracts all row metadata correctly
- Maps cell values to correct columns
- Handles multiple affiliations in team rows
- Detects cut status correctly

### Step 2.4: Detect Cut Lines
**File**: `lib/golf_genius/scoreboard/html_parser.rb`

- [ ] Implement `parse_cut_text(html_doc)` method
- [ ] Find `<tr class='header'>` containing `<td class='cut_list_tr'>`
- [ ] Extract text content for cut text
- [ ] Mark all subsequent aggregate rows as `cut: true`
- [ ] Return cut text (or nil)

**Test**:
- Extracts cut text from HTML
- Marks rows below cut line with `cut: true`
- Returns nil when no cut exists
- Handles position "CUT" in cells

### Step 2.5: Organize Columns by Scope
**File**: `lib/golf_genius/scoreboard/html_parser.rb`

- [ ] Implement `organize_columns(columns, rounds_metadata)` method
- [ ] Split columns into `summary` and `rounds` groups
- [ ] For round columns, group by round_id
- [ ] Return structured column schema matching PRD format

**Test**:
- Summary columns separated from round columns
- Round columns grouped by round_id
- Round metadata attached to each round group

### Step 2.6: Organize Row Cells by Scope
**File**: `lib/golf_genius/scoreboard/html_parser.rb`

- [ ] Implement `organize_row_cells(row, columns)` method
- [ ] Split cell values into `summary` and `rounds` hashes
- [ ] For round cells, nest under round_id
- [ ] Return row structure matching PRD format

**Test**:
- Summary cells separated from round cells
- Round cells keyed by round_id
- Cell keys match column keys

## Phase 3: JSON Parsing & Injection

### Step 3.1: Parse JSON Response
**File**: `lib/golf_genius/scoreboard/json_parser.rb`

- [ ] Create `JSONParser` class
- [ ] Implement `parse(json_data)` method
- [ ] Extract tournament-level metadata:
  - `adjusted` flag
  - `rounds` array
- [ ] Extract aggregate data:
  - Match aggregates by `id`
  - Extract per-round data from `rounds[]` array
  - Extract current round hole-by-hole data
  - Extract previous rounds data from `previous_rounds_scores[]`
- [ ] Return structured metadata hash

**Test**:
- Extracts tournament metadata correctly
- Parses aggregate hole-by-hole data
- Matches aggregates by ID
- Handles multiple rounds in data

### Step 3.2: Inject JSON Metadata into Rows
**File**: `lib/golf_genius/scoreboard/json_injector.rb`

- [ ] Create `JSONInjector` class
- [ ] Implement `inject(rows, json_metadata, round_id)` method
- [ ] Match HTML rows to JSON aggregates by `id`
- [ ] For each match, inject into `scorecard` namespace:
  - `thru`, `score`, `status` (collapsed from array)
  - `gross_scores`, `net_scores`, `to_par_gross`, `to_par_net`
  - `totals`
- [ ] Handle current round vs previous rounds data
- [ ] Raise error if row has no matching aggregate

**Test**:
- Matches rows to aggregates correctly
- Injects scorecard data under correct round_id
- Collapses scorecard_statuses array to single status
- Raises error on missing aggregate
- Handles previous rounds data

### Step 3.3: Validate HTML/JSON Consistency
**File**: `lib/golf_genius/scoreboard/validator.rb`

- [ ] Create `Validator` class
- [ ] Implement validation checks:
  - Player counts match between HTML and JSON
  - All HTML rows have JSON aggregates
  - player_ids match between HTML and JSON
  - Round IDs in JSON exist in rounds metadata
- [ ] Raise specific errors for each validation failure

**Test**:
- Detects mismatched player counts
- Detects missing aggregates
- Detects player_id mismatches
- Detects invalid round references

## Phase 4: Tournament Assembly

### Step 4.1: Fetch & Parse Single Tournament
**File**: `lib/golf_genius/scoreboard.rb`

- [ ] Implement `fetch_tournament(tournament_id, round_id)` method
- [ ] Call `Event.tournament_results(round_id:, tournament_id:, format: :html)`
- [ ] Call `Event.tournament_results(round_id:, tournament_id:, format: :json)`
- [ ] Parse HTML via `HTMLParser`
- [ ] Parse JSON via `JSONParser`
- [ ] Inject JSON via `JSONInjector`
- [ ] Validate via `Validator`
- [ ] Return tournament hash matching PRD schema

**Test**:
- Fetches both HTML and JSON
- Parses and combines correctly
- Returns correct schema structure
- Handles errors gracefully

### Step 4.2: Fetch All Tournaments
**File**: `lib/golf_genius/scoreboard.rb`

- [ ] Implement `fetch_all_tournaments` method
- [ ] Iterate through resolved tournament list
- [ ] Call `fetch_tournament` for each
- [ ] Collect results into array
- [ ] Handle partial failures (fail hard)

**Test**:
- Fetches all tournaments for a round
- Returns array of tournament hashes
- Fails if any tournament fails

### Step 4.3: Build Top-Level Schema
**File**: `lib/golf_genius/scoreboard.rb`

- [ ] Implement `build_schema` method
- [ ] Construct top-level meta (event_id, event_name, round_id, round_name)
- [ ] Attach tournaments array
- [ ] Return complete schema matching PRD

**Test**:
- Returns correct top-level structure
- Includes all tournaments
- Meta fields populated correctly

### Step 4.4: Implement `to_h` Method
**File**: `lib/golf_genius/scoreboard.rb`

- [ ] Call `build_schema` and cache result
- [ ] Return cached schema on subsequent calls
- [ ] Implement `tournaments` accessor
- [ ] Implement `tournament(id_or_name)` finder

**Test**:
- `to_h` returns complete schema
- Result is memoized
- Accessors work correctly

## Phase 5: Helper Methods

### Step 5.1: Implement `rows` Accessor
**File**: `lib/golf_genius/scoreboard.rb`

- [ ] Implement `rows` method
- [ ] Collect all rows from all tournaments
- [ ] Decorate each with `tournament_id`
- [ ] Return flat array

**Test**:
- Returns all rows across tournaments
- Each row has tournament_id
- Preserves row data

### Step 5.2: Implement Score Normalization Utilities
**File**: `lib/golf_genius/scoreboard/score_utils.rb`

- [ ] Create `ScoreUtils` module
- [ ] Implement `normalize_score(score_string)` method
  - "E" → 0
  - "+5" → 5
  - "-3" → -3
  - "T2" → 2 (strip "T")
  - "CUT", "WD", "DQ" → Float::INFINITY (sorts to bottom)
- [ ] Handle edge cases

**Test**:
- Normalizes all score formats correctly
- Handles special statuses
- Returns numeric values for sorting

### Step 5.3: Implement `filter` Method
**File**: `lib/golf_genius/scoreboard.rb`

- [ ] Implement `filter(tournament_id:, field:, value:)` method
- [ ] Find tournament by ID
- [ ] Filter rows where field matches value
- [ ] Return new Scoreboard instance with filtered data

**Test**:
- Filters rows correctly
- Preserves other tournaments
- Returns new instance

### Step 5.4: Implement `sort` Method
**File**: `lib/golf_genius/scoreboard.rb`

- [ ] Implement `sort(tournament_id:, field:, direction: :asc)` method
- [ ] Find tournament by ID
- [ ] Sort rows using `ScoreUtils.normalize_score` for golf scores
- [ ] Use stable sort
- [ ] Return new Scoreboard instance

**Test**:
- Sorts by numeric fields correctly
- Sorts golf scores correctly (E, +1, -3, etc.)
- Maintains stable sort order
- Handles CUT/WD/DQ at bottom

### Step 5.5: Implement Column Filtering
**File**: `lib/golf_genius/scoreboard.rb`

- [ ] Implement `select_columns(tournament_id:, formats: [])` method
- [ ] Implement `reject_columns(tournament_id:, formats: [])` method
- [ ] Filter columns by `format` field
- [ ] Filter corresponding row cells
- [ ] Return new Scoreboard instance

**Test**:
- Filters columns by format
- Removes corresponding cells from rows
- Preserves other data

## Phase 6: Integration & Testing

### Step 6.1: Integration Tests with Real Data
**File**: `spec/golf_genius/scoreboard_integration_spec.rb`

- [ ] Test against `tmp/tournament_results/leaderboard-testing-event-522157/`
- [ ] Test R1 (single round complete)
- [ ] Test R2 (multi-round in-progress)
- [ ] Test all three tournaments (Overall, 16-18, 15 & Under)
- [ ] Verify schema matches PRD exactly

**Test**:
- Loads real HTML/JSON files
- Produces correct schema
- Handles all tournament types

### Step 6.2: Edge Case Testing
**File**: `spec/golf_genius/scoreboard_spec.rb`

- [ ] Test with cut lines
- [ ] Test with team rows (multiple players)
- [ ] Test with skins format (no round columns)
- [ ] Test with match play format
- [ ] Test error conditions (missing data, mismatches)

**Test**:
- All edge cases handled
- Errors raised appropriately
- Schema correct for all formats

### Step 6.3: Performance Testing
**File**: `spec/golf_genius/scoreboard_performance_spec.rb`

- [ ] Test with large events (100+ players)
- [ ] Measure parsing time
- [ ] Ensure memoization works
- [ ] Profile memory usage

**Test**:
- Acceptable performance
- No memory leaks
- Memoization effective

## Phase 7: Documentation & Polish

### Step 7.1: Add YARD Documentation
- [ ] Document all public methods
- [ ] Add usage examples
- [ ] Document error conditions
- [ ] Add type signatures

### Step 7.2: Create Usage Examples
**File**: `examples/scoreboard_usage.rb`

- [ ] Example: Fetch latest results
- [ ] Example: Alpha board (sorted by name)
- [ ] Example: Summary board (all tournaments, sorted by score)
- [ ] Example: Filter to specific players
- [ ] Example: Hide specific columns

### Step 7.3: Update README
**File**: `README.md`

- [ ] Add Scoreboard section
- [ ] Link to PRD
- [ ] Show basic usage
- [ ] Document helper methods

## Estimated Effort

- **Phase 1**: 2-3 hours (foundation)
- **Phase 2**: 6-8 hours (HTML parsing, most complex)
- **Phase 3**: 4-5 hours (JSON parsing & injection)
- **Phase 4**: 3-4 hours (assembly)
- **Phase 5**: 3-4 hours (helpers)
- **Phase 6**: 4-6 hours (testing)
- **Phase 7**: 2-3 hours (docs)

**Total**: ~24-33 hours

## Dependencies

- Nokogiri (already in project for HTML parsing)
- Existing `GolfGenius::Resource` classes (Event, Round, Tournament, TournamentResults)
- RSpec (for testing)

## Success Criteria

- [ ] All tests pass
- [ ] Schema matches PRD exactly
- [ ] Works with all tournament formats in test data
- [ ] Error handling comprehensive
- [ ] Performance acceptable
- [ ] Documentation complete
- [ ] Usage examples clear
