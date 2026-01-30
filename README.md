# Golf Genius Ruby

Ruby client for the [Golf Genius API v2](https://www.golfgenius.com/api/v2/docs). Read-only access to seasons, categories, directories, and events.

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

To use the console locally with staging or production, create `.env.staging` or `.env.production` with `GOLF_GENIUS_API_KEY=your_key`, and set `GOLF_GENIUS_ENV=staging` or `production` as needed. See [.env.example](.env.example).

---

## Resources (alphabetical)

### Category

**List all categories**

```ruby
GolfGenius::Category.list
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
```

```ruby
# => #<GolfGenius::Category id="cat_001" name="Member Events" color="#FF5733" event_count=15 archived=false>
```

---

### Directory

**List all directories**

```ruby
GolfGenius::Directory.list
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
```

```ruby
# => #<GolfGenius::Directory id="dir_001" name="Main Directory" event_count=25 all_events=false>
```

---

### Event

**List events** (optionally filter by directory, season, category; by default non-archived only)

```ruby
dir = GolfGenius::Directory.list.first
GolfGenius::Event.list(directory: dir)
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
GolfGenius::Event.fetch("zphsqa")
```

```ruby
# => #<GolfGenius::Event id="event_001" name="Spring Championship" type="tournament" date="2026-04-15" location="Pine Valley Golf Club" archived=false ...>
```

**Event roster** (players; pass `photo: true` to include profile picture URLs)

```ruby
GolfGenius::Event.roster("event_001", photo: true)
```

```ruby
# => [
#   #<GolfGenius::GolfGeniusObject id="player_001" name="John Smith" email="john@example.com" handicap=12.5 tee="Blue" photo_url="https://...">,
#   #<GolfGenius::GolfGeniusObject id="player_002" name="Jane Doe" ...>
# ]
```

**Event rounds**

```ruby
GolfGenius::Event.rounds("event_001")
```

```ruby
# => [
#   #<GolfGenius::GolfGeniusObject id="round_001" number=1 date="2026-04-15" format="stroke_play" status="completed">,
#   #<GolfGenius::GolfGeniusObject id="round_002" number=2 date="2026-04-16" status="scheduled">
# ]
```

**Event courses** (tees / ratings)

```ruby
GolfGenius::Event.courses("event_001")
```

```ruby
# => [
#   #<GolfGenius::GolfGeniusObject id="course_001" name="Pine Valley - Championship" tee="Blue" rating=74.5 slope=145 par=72>,
#   #<GolfGenius::GolfGeniusObject id="course_002" name="Pine Valley - Championship" tee="White" rating=71.2 slope=138 par=72>
# ]
```

**Tournaments for a round**

```ruby
GolfGenius::Event.tournaments("event_001", "round_001")
```

```ruby
# => [
#   #<GolfGenius::GolfGeniusObject id="tourn_001" name="Flight A - Gross" type="individual" scoring="gross" status="completed">,
#   #<GolfGenius::GolfGeniusObject id="tourn_002" name="Flight A - Net" scoring="net" status="completed">
# ]
```

---

### Season

**List all seasons**

```ruby
GolfGenius::Season.list
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
```

```ruby
# => #<GolfGenius::Season id="season_001" name="2026 Season" current=true start_date="2026-01-01" end_date="2026-12-31">
```

---

## Multiple API keys (client)

Use a dedicated client when you need a different API key than the global one:

```ruby
client = GolfGenius::Client.new(api_key: "your_key")
client.seasons.list
client.events.list(directory: dir)
client.events.fetch(171716)
client.events.roster("event_001")
```

---

## Advanced options

- **Pagination:** `list` fetches all pages by default. To request a single page, pass `page: 1`. For streaming, use `GolfGenius::Event.auto_paging_each(directory: dir) { |e| ... }`.
- **Event filters:** `list(directory: dir, season: season, category: cat, archived: true)` — pass resource objects or ids; default is non-archived only.
- **Fetch:** Event supports lookup by `id` or `ggid`; other resources by `id`. Optional `max_pages` for fetch (default 20).
- **Environment:** Production is `golfgenius.com`. Staging is `ggstest.com`. Set `GOLF_GENIUS_ENV=staging` or `GOLF_GENIUS_BASE_URL` to override.
- **Debug:** `GolfGenius.debug = true` logs each request and response to `$stdout`. The API key is never logged.

---

## Development

```bash
bundle install
bin/console   # then reload! after editing lib/
bundle exec rake test
```

- [QUICKSTART.md](QUICKSTART.md) – example-focused guide
- [RAILS_SETUP.md](RAILS_SETUP.md) – Rails integration
- [API docs](https://www.golfgenius.com/api/v2/docs) (staging: `https://ggstest.com`)

## License

MIT
