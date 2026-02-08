# Golf Genius Ruby

Ruby client for the [Golf Genius API v2](https://www.golfgenius.com/api/v2/docs). Read-only access to seasons, categories, directories, events, and players.

Supported Ruby: 3.1+

## Install

```ruby
# Gemfile
gem "golf-genius", github: "ohiogolf/golf-genius-ruby"
```

```bash
bundle install
```

## Setup

```ruby
require "golf_genius"

GolfGenius.api_key = ENV["GOLF_GENIUS_API_KEY"]
```

---

## Quick Start

```ruby
events = GolfGenius::Event.list(page: 1)
# => [#<GolfGenius::Event id="event_001" name="Spring Championship" ...>, ...]
event = GolfGenius::Event.fetch(events.first.id)
# => #<GolfGenius::Event id="event_001" name="Spring Championship" ...>
event = GolfGenius::Event.fetch_by(ggid: "zphsqa")
# => #<GolfGenius::Event id="event_001" name="Spring Championship" ...>

roster = event.roster(photo: true)
# => [#<GolfGenius::RosterMember id="player_001" ...>, ...]
player = roster.first
# => #<GolfGenius::RosterMember id="player_001" name="John Smith" ...>
player.handicap.index
# => "12.5"
```

---

## Common Tasks

### Fetch And Lookup

```ruby
GolfGenius::Event.fetch("event_001")
# => #<GolfGenius::Event id="event_001" name="Spring Championship" ...>
GolfGenius::Event.fetch_by(ggid: "zphsqa")
# => #<GolfGenius::Event id="event_001" name="Spring Championship" ...>
GolfGenius::Player.fetch_by(email: "john@doe.com")
# => #<GolfGenius::Player id="player_001" name="John Smith" ...>
GolfGenius::Player.fetch_by(id: "player_001")
# => #<GolfGenius::Player id="player_001" name="John Smith" ...>
```

### Event Data

```ruby
event = GolfGenius::Event.fetch("event_001")
# => #<GolfGenius::Event id="event_001" name="Spring Championship" ...>
event.roster(photo: true)
# => [#<GolfGenius::RosterMember id="player_001" ...>, ...]
event.rounds
# => [#<GolfGenius::Round id="round_001" ...>, ...]
event.rounds.first.tournaments
# => [#<GolfGenius::Tournament id="tourn_001" ...>, ...]
tournament = event.rounds.first.tournaments.first
tournament.results
# => #<GolfGenius::TournamentResults title="Flight A - Gross" ...>   # default format: :json
tournament.results(format: :html)
# => "<div class='table-responsive'>..."
```

### Scoreboard (Live Results)

```ruby
# Get live leaderboard for latest round
scoreboard = GolfGenius::Scoreboard.new(event: "522157")
# => #<GolfGenius::Scoreboard ...>

# Access tournaments and players
scoreboard.tournaments.first.name
# => "Championship Flight"
scoreboard.tournaments.first.rows.first.position
# => "T2"

# Sort alphabetically for alpha board
alpha_board = scoreboard.sort(:last_name)

# Competing players first, then alphabetical
sorted = scoreboard.sort(:competing, :last_name)
sorted.tournaments.first.rows.each do |row|
  puts "#{row.last_name}, #{row.first_name} - #{row.affiliation_city}, #{row.affiliation_state}"
end

# Filter players
tournament = scoreboard.tournaments.first
tournament.rows.select(&:eliminated?)
# => [#<Row position="CUT" ...>, ...]

# Check current round status
current_round = tournament.rounds.current
# => #<Round name="R2" playing?=true>
current_round.playing?
# => true
```

See [docs/scoreboard-usage-guide.md](docs/scoreboard-usage-guide.md) for detailed examples.

### Event Filters

```ruby
dir = GolfGenius::Directory.list.first
# => #<GolfGenius::Directory id="dir_001" name="Main Directory" ...>
season = GolfGenius::Season.list.first
# => #<GolfGenius::Season id="season_001" name="2026 Season" ...>
GolfGenius::Event.list(directory: dir, archived: true)
# => [#<GolfGenius::Event id="event_010" ...>, ...]
GolfGenius::Event.list(season: season)
# => [#<GolfGenius::Event id="event_001" ...>, ...]
```

### Pagination

```ruby
GolfGenius::Event.list(page: 1) # single page
# => [#<GolfGenius::Event id="event_001" ...>, ...]
GolfGenius::Event.list          # all pages
# => [#<GolfGenius::Event id="event_001" ...>, ...]
```

---

## Advanced Options

- **Raw API payloads:** `object.to_h(raw: true)`
- **Debug logging:** `GolfGenius.debug = true` logs each request and response to `$stdout`.
- **Environment:** Production is `golfgenius.com`. Staging is `ggstest.com`. Set `GOLF_GENIUS_ENV=staging` or `GOLF_GENIUS_BASE_URL`.
- **Pagination helpers:** `auto_paging_each` and `list_all` for large datasets.
- **Fetch limits:** `fetch`/`fetch_by` stop after `max_pages` (default 20); `list`/`list_all` are not capped.

---

## Configuration Summary

- `api_key` (required)
- `base_url` (optional override)
- `debug` (boolean, default false)
- `logger` (defaults to `nil` unless debug enabled)
- `log_level` (defaults to `:info`)

```ruby
GolfGenius.configure do |config|
  config.api_key = ENV["GOLF_GENIUS_API_KEY"]
  config.debug = true
  config.log_level = :debug
end
# => nil
```

---

## Error Handling

```ruby
begin
  GolfGenius::Event.fetch("missing")
rescue GolfGenius::NotFoundError => error
  error.message
  # => "Resource not found: missing"
end
```

Common exceptions include:

- `GolfGenius::ConfigurationError` (missing API key)
- `GolfGenius::NotFoundError` (no match found)
- `GolfGenius::AuthenticationError` (invalid API key)
- `GolfGenius::APIError` (unexpected HTTP status)

---

## Glossary

| Term | Meaning |
|------|--------|
| **Event** | The overall thing you’re running: an outing, championship, league, or trip. Has a name, dates, location, registration, and type (`"event"`, `"league"`, `"trip"`). In the Golf Genius web UI, these are often shown under `leagues/<id>` URLs, but they map to the same event records. |
| **Season** | A time bucket for organizing events (e.g. “2026 Season”). Top-level; events can be filtered by season. |
| **Category** | A label/group for events (e.g. “Member Events”, “Championships”). Top-level; events can be filtered by category. |
| **Directory** | A folder/list of events in the customer center (e.g. “All Leagues & Events”). Top-level; an event can appear in multiple directories. |
| **Round** | One day (or unit) of play within an event. An event can have multiple rounds (Round 1, Round 2, …). Each has a date, status, pairing size, and settings. |
| **Course** | A course and its tees used for the event (name, tees, pars, ratings). Courses are defined at the event level only. |
| **Division** | A grouping for play within an event (e.g. flight, tee time block). External divisions from the API; has name, status, position, tee_times. |
| **Tournament** | In the API, a competition/flight/game within a single round (e.g. “Individual Gross”, “Net Flight A”), not the whole event. One round can have multiple tournaments. |
| **TournamentResults** | Raw results payload for a tournament within a round. Returned by `tournament.results` or `event.tournament_results`. |
| **Roster** | The list of players/members in an event. Each item is a **RosterMember**. |

---

## Resources (Alphabetical)

### Category

**List all categories**

```ruby
GolfGenius::Category.list
# => [#<GolfGenius::Category id="cat_001" name="Member Events" ...>, ...]
```

```ruby
# => [
#   #<GolfGenius::Category id="cat_001" name="Member Events" color="#FF5733" event_count=15 archived=false>,
#   #<GolfGenius::Category id="cat_002" name="Guest Events" color="#33FF57" event_count=8 archived=false>
# ]
```

**Fetch one category by id**

```ruby
GolfGenius::Category.fetch("cat_001")
# => #<GolfGenius::Category id="cat_001" name="Member Events" ...>
GolfGenius::Category.fetch_by(id: "cat_001")
# => #<GolfGenius::Category id="cat_001" name="Member Events" ...>
```

```ruby
# => #<GolfGenius::Category id="cat_001" name="Member Events" color="#FF5733" event_count=15 archived=false>
```

---

### Directory

**List all directories**

```ruby
GolfGenius::Directory.list
# => [#<GolfGenius::Directory id="dir_001" name="Main Directory" ...>, ...]
```

```ruby
# => [
#   #<GolfGenius::Directory id="dir_001" name="Main Directory" event_count=25 all_events=false>,
#   #<GolfGenius::Directory id="dir_002" name="Archive Directory" event_count=100 all_events=true>
# ]
```

**Fetch one directory by id**

```ruby
GolfGenius::Directory.fetch("dir_001")
# => #<GolfGenius::Directory id="dir_001" name="Main Directory" ...>
GolfGenius::Directory.fetch_by(id: "dir_001")
# => #<GolfGenius::Directory id="dir_001" name="Main Directory" ...>
```

```ruby
# => #<GolfGenius::Directory id="dir_001" name="Main Directory" event_count=25 all_events=false>
```

---

### Event

**List events** (optionally filter by directory, season, category; by default non-archived only)

```ruby
dir = GolfGenius::Directory.list.first
# => #<GolfGenius::Directory id="dir_001" name="Main Directory" ...>
events = GolfGenius::Event.list(directory: dir)
# => [#<GolfGenius::Event id="event_001" name="Spring Championship" ...>, ...]
```

```ruby
# => [
#   #<GolfGenius::Event id="event_001" name="Spring Championship" type="tournament" date="2026-04-15" location="Pine Valley Golf Club" archived=false ...>,
#   #<GolfGenius::Event id="event_002" name="Summer Outing" type="outing" date="2026-07-20" ...>
# ]
```

**Fetch one event by id or ggid**

```ruby
GolfGenius::Event.fetch(171716)
# or by short ggid:
GolfGenius::Event.fetch_by(ggid: "zphsqa")
# => #<GolfGenius::Event id="event_001" name="Spring Championship" ...>
```

```ruby
# By default, fetch tries non-archived first, then falls back to archived.
GolfGenius::Event.fetch(171716)

# Explicit :archived scopes (no fallback):
GolfGenius::Event.fetch(171716, archived: false) # non-archived only
GolfGenius::Event.fetch(171716, archived: true)  # archived only

# The same behavior applies when fetching by ggid:
GolfGenius::Event.fetch_by(ggid: "zphsqa")
GolfGenius::Event.fetch_by(ggid: "zphsqa", archived: false)
GolfGenius::Event.fetch_by(ggid: "zphsqa", archived: true)
```

```ruby
# => #<GolfGenius::Event id="event_001" name="Spring Championship" type="tournament" date="2026-04-15" location="Pine Valley Golf Club" archived=false ...>
```

**Event roster** (players; pass `photo: true` to include profile picture URLs)

```ruby
event = GolfGenius::Event.fetch("event_001")
# => #<GolfGenius::Event id="event_001" name="Spring Championship" ...>
event.roster(photo: true)
# => [#<GolfGenius::RosterMember id="player_001" ...>, ...]
```

```ruby
# => [
#   #<GolfGenius::RosterMember id="player_001" name="John Smith" email="john@example.com" handicap=#<GolfGenius::Handicap network_id="123" index="12.5" ...> tee=#<GolfGenius::Tee name="Blue" ...> photo_url="https://...">,
#   #<GolfGenius::RosterMember id="player_002" name="Jane Doe" ...>
# ]
```

**Event rounds** (each round has `event_id` so you can call `round.tournaments`)

```ruby
event.rounds
# => [#<GolfGenius::Round id="round_001" ...>, ...]
```

```ruby
# => [
#   #<GolfGenius::Round id="round_001" number=1 date="2026-04-15" format="stroke_play" status="completed">,
#   #<GolfGenius::Round id="round_002" number=2 date="2026-04-16" status="scheduled">
# ]
```

**Event courses** (tees / ratings; courses are at event level only)

```ruby
event.courses
# => [#<GolfGenius::Course id="course_001" ...>, ...]
```

```ruby
# => [
#   #<GolfGenius::Course id="course_001" name="Pine Valley - Championship" tee="Blue" rating=74.5 slope=145 par=72>,
#   #<GolfGenius::Course id="course_002" name="Pine Valley - Championship" tee="White" rating=71.2 slope=138 par=72>
# ]
```

**Event divisions** (external divisions: name, status, position, tee_times)

```ruby
event.divisions
# => [#<GolfGenius::Division id="2794531013441653808" ...>, ...]
```

```ruby
# => [
#   #<GolfGenius::Division id="2794531013441653808" name="Division Test" status="not started" position=0 ...>,
#   #<GolfGenius::Division id="div_002" name="Flight B" status="in progress" position=1 ...>
# ]
```

**Tournaments for a round** (pass round id or Round object)

```ruby
round = event.rounds.first
# => #<GolfGenius::Round id="round_001" ...>
round.tournaments
# => [#<GolfGenius::Tournament id="tourn_001" ...>, ...]
```

```ruby
# => [
#   #<GolfGenius::Tournament id="tourn_001" name="Flight A - Gross" type="individual" scoring="gross" status="completed">,
#   #<GolfGenius::Tournament id="tourn_002" name="Flight A - Net" scoring="net" status="completed">
# ]
```

**Tee sheet and scores for a round**

```ruby
round.tee_sheet
# => [#<GolfGenius::TeeSheetGroup id="group_001" ...>, ...]
```

```ruby
# => [
#   #<GolfGenius::TeeSheetGroup id="group_001" hole=1 tee_time="8:30 AM" ...>
# ]
```

**Tournament results for a round tournament**

```ruby
tournament = event.rounds.first.tournaments.first
tournament.results
# => #<GolfGenius::TournamentResults title="Flight A - Gross" ...>   # default format: :json
event.tournament_results(round.id, tournament.id)
# => #<GolfGenius::TournamentResults title="Flight A - Gross" ...>   # default format: :json

tournament.results(format: :html)
# => "<div class='table-responsive'>..."
event.tournament_results(round.id, tournament.id, format: :html)
# => "<div class='table-responsive'>..."
```

---

### Player

**List all players (master roster)**

```ruby
GolfGenius::Player.list
# => [#<GolfGenius::Player id="player_001" name="John Smith" ...>, ...]
```

**Fetch one player by email or id**

```ruby
GolfGenius::Player.fetch_by(email: "john@doe.com")
# => #<GolfGenius::Player id="player_001" name="John Smith" ...>
GolfGenius::Player.fetch_by(id: "player_001")
# => #<GolfGenius::Player id="player_001" name="John Smith" ...>
```

**Player events**

```ruby
player = GolfGenius::Player.fetch_by(email: "john@doe.com")
# => #<GolfGenius::Player id="player_001" name="John Smith" ...>
player.events
# => #<GolfGenius::GolfGeniusObject member=#<GolfGenius::Player ...> events=["event_001", "event_002"]>
```

---

### Season

**List all seasons**

```ruby
GolfGenius::Season.list
# => [#<GolfGenius::Season id="season_001" name="2026 Season" ...>, ...]
```

```ruby
# => [
#   #<GolfGenius::Season id="season_001" name="2026 Season" current=true start_date="2026-01-01" end_date="2026-12-31">,
#   #<GolfGenius::Season id="season_002" name="2025 Season" current=false start_date="2025-01-01" end_date="2025-12-31">
# ]
```

**Fetch one season by id**

```ruby
GolfGenius::Season.fetch("season_001")
# => #<GolfGenius::Season id="season_001" name="2026 Season" ...>
GolfGenius::Season.fetch_by(id: "season_001")
# => #<GolfGenius::Season id="season_001" name="2026 Season" ...>
```

```ruby
# => #<GolfGenius::Season id="season_001" name="2026 Season" current=true start_date="2026-01-01" end_date="2026-12-31">
```

---

## Multiple API Keys (Client)

Use a dedicated client when you need a different API key than the global one:

```ruby
client = GolfGenius::Client.new(api_key: "your_key")
client.seasons.list
# => [#<GolfGenius::Season id="season_001" ...>, ...]
client.events.list(directory: dir)
# => [#<GolfGenius::Event id="event_001" ...>, ...]
client.events.fetch(171716)
# => #<GolfGenius::Event id="event_001" ...>
client.events.fetch_by(ggid: "zphsqa")
# => #<GolfGenius::Event id="event_001" ...>
client.events.roster("event_001")
# => [#<GolfGenius::RosterMember id="player_001" ...>, ...]
```

---

## Development

For console usage, create `.env.staging` or `.env.production` with `GOLF_GENIUS_API_KEY=your_key`, then set `GOLF_GENIUS_ENV=staging` or `production` as needed. See [.env.example](.env.example).

```bash
bundle install
bin/console   # then reload! after editing lib/
bin/lint
bin/test
```

- [QUICKSTART.md](QUICKSTART.md) – example-focused guide
- [RAILS_SETUP.md](RAILS_SETUP.md) – Rails integration
- [API docs](https://www.golfgenius.com/api/v2/docs) (staging: `https://ggstest.com`)

## License

MIT
