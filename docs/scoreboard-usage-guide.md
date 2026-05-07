# Scoreboard Usage Guide

`GolfGenius::Scoreboard` now returns a single normalized JSON-shaped payload. The old HTML-derived wrapper objects (`tournaments`, `rows`, `cells`) are gone.

## Quick Start

```ruby
scoreboard = GolfGenius::Scoreboard.new(event: "522157")
payload = scoreboard.to_h
```

You can also scope to a specific round or tournament:

```ruby
scoreboard = GolfGenius::Scoreboard.new(
  event: "522157",
  round: "1615931",
  tournament: "4522280"
)

payload = scoreboard.to_h
```

## Payload Shape

```ruby
{
  meta: {
    event_id: "522157",
    event_name: "Spring Championship",
    selected_round: { id: "1615931", name: "R2", state: "playing", ... },
    current_round: { id: "1615931", name: "R2", state: "playing", ... }
  },
  rounds: [
    { id: "1615930", name: "R1", state: "finished", ... },
    { id: "1615931", name: "R2", state: "playing", ... }
  ],
  tournaments: [
    {
      id: "4522280",
      name: "Overall Results",
      adjusted: false,
      source_round: { id: "1615931", name: "R2", state: "playing", ... },
      columns: {
        position: { label: "Pos.", visible: true, ... },
        score: { label: "To Par Gross", visible: true, ... }
      },
      entries: [
        {
          id: "99",
          name: "Jane Doe (a)",
          position: "T2",
          rank: 2,
          state: "playing",
          outcome: nil,
          players: [...],
          rounds: {
            "1615931" => {
              state: "playing",
              tee_time: "8:30 AM",
              thru: "8",
              score: "-2",
              total: nil
            }
          }
        }
      ]
    }
  ]
}
```

## Meta

`payload[:meta]` contains:

- `:event_id` and `:event_name`
- `:selected_round` — the round the scoreboard resolved to
- `:current_round` — the current event round according to the shared round-selection rules

Example:

```ruby
payload[:meta][:event_name]
# => "Spring Championship"

payload[:meta][:selected_round][:name]
# => "R2"
```

## Rounds

`payload[:rounds]` is the normalized event-round list.

Each round includes:

- `:id`
- `:name`
- `:date`
- `:index`
- `:state`
- `:status`

Example:

```ruby
payload[:rounds].each do |round|
  puts "#{round[:name]} (#{round[:date]}): #{round[:state]}"
end
```

Round state values are shared constants inside the gem and are consistent at the top level and inside per-entry round payloads:

- `not_started`
- `playing`
- `finished`
- `eliminated`

## Tournaments

`payload[:tournaments]` is an array of normalized scoring tournaments.

Each tournament includes:

- `:id`
- `:name`
- `:adjusted`
- `:source_round`
- `:cut_list_position`
- `:display_cut`
- `:horizontal_leaderboard`
- `:columns`
- `:entries`

Example:

```ruby
tournament = payload[:tournaments].first
tournament[:name]
# => "Overall Results"
```

## Columns

`columns` is a hash keyed by the normalized column name from the tournament-results JSON.

Column labels are cleaned for caller use:

- HTML tags are removed
- HTML entities are decoded
- URL-style encodings such as `%2C` are decoded

Example:

```ruby
tournament[:columns]["score"][:label]
# => "To Par Gross"
```

## Entries

`entries` is the player/team list for a tournament.

Each entry includes:

- `:id`
- `:name`
- `:position`
- `:rank`
- `:state`
- `:outcome`
- `:outcome_cause`
- `:details`
- `:players`
- `:rounds`

Example:

```ruby
entry = payload[:tournaments].first[:entries].first
entry[:position]
# => "T2"
entry[:state]
# => "playing"
```

### Entry State

`entry[:state]` is the canonical machine-readable entry state. This is broader than `outcome`.

Typical values:

- `not_started`
- `playing`
- `finished`
- `eliminated`

### Entry Outcome

`entry[:outcome]` is only for exceptional dispositions, not normal finishes.

Typical values:

- `nil`
- `cut`
- `wd`
- `dq`
- `ns`
- `dns`
- `mc`
- `nc`
- `unknown`

Use `state` to answer “what is this entry doing?” and `outcome` to answer “did Golf Genius mark a special disposition?”

## Players

`entry[:players]` is the canonical player/team-member data.

Each player includes:

- `:member_id`
- `:member_card_id`
- `:player_roster_id`
- `:ggid`
- `:name`
- `:location`
- `:tee`

Example:

```ruby
player = entry[:players].first
player[:name][:full]
# => "Jane Doe (a)"
player[:name][:amateur]
# => true
```

### Name Parsing

The gem normalizes player names for you:

- `:full`
- `:first`
- `:last`
- `:suffix`
- `:amateur`

### Location

`player[:location]` keeps the raw value and adds normalized structure when the gem can classify it with confidence.

Example:

```ruby
player[:location]
# => {
#      raw: "Columbus, OH",
#      kind: "city_state",
#      city: "Columbus",
#      state: "OH",
#      state_name: "Ohio",
#      country: { name: "United States", alpha2: "US", alpha3: "USA", ioc: "USA" }
#    }
```

`kind` is typically one of:

- `city_state`
- `country`
- `freeform`
- `unknown`

## Per-Entry Rounds

`entry[:rounds]` is keyed by round id string.

Each round payload can include:

- `:state`
- `:tee_time`
- `:starting_hole`
- `:thru`
- `:score`
- `:total`
- `:to_par_display`
- `:to_par_total`
- `:stroke_totals`
- `:gross_scores`
- `:net_scores`
- `:gross_to_par`
- `:net_to_par`
- `:tee`

Example:

```ruby
selected_round_id = payload[:meta][:selected_round][:id]
round_data = entry[:rounds][selected_round_id]

round_data[:state]
# => "playing"
round_data[:tee_time]
# => "8:30 AM"
round_data[:to_par_display]
# => "-2"
```

## Sorting

`Scoreboard#sort` still returns a new `Scoreboard`, but it sorts each tournament’s `entries` array inside the normalized payload.

Supported sort keys:

- `:competing`
- `:position`
- `:last_name`

Examples:

```ruby
scoreboard.sort(:last_name).to_h
scoreboard.sort(:competing, :last_name).to_h
scoreboard.sort(:position, direction: :desc).to_h
```

## Notes

- All ids in the normalized payload are strings.
- Blank strings are normalized to `nil` where they do not carry meaning.
- The scoreboard is JSON-first and no longer depends on the old HTML table parser.
