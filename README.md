# Golf Genius Ruby

Ruby client for the [Golf Genius API v2](https://www.golfgenius.com/api/v2/docs). Read-only access to seasons, categories, directories, and events.

**Environments:** Production is at `www.golfgenius.com`. A staging API is at **ggstest.com**. You can set the base URL globally via **`GOLF_GENIUS_ENV=staging`** (uses ggstest.com) or **`GOLF_GENIUS_BASE_URL`** (any URL); otherwise the client defaults to production.

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
# Or: GolfGenius.configure { |c| c.api_key = "..." }

# Optional: use staging — set env GOLF_GENIUS_ENV=staging (or GOLF_GENIUS_BASE_URL), or:
# GolfGenius.base_url = "https://ggstest.com"
```

## Usage

**Seasons, categories, directories**

```ruby
GolfGenius::Season.list
GolfGenius::Season.fetch("season_id")

GolfGenius::Category.list
GolfGenius::Category.fetch("category_id")

GolfGenius::Directory.list
GolfGenius::Directory.fetch("directory_id")
```

**Events (list, filter, fetch)**

```ruby
# list() fetches all pages by default
GolfGenius::Event.list(directory: dir)
# Single page only: pass page
GolfGenius::Event.list(page: 1, directory: dir, season: season, category: cat, archived: false)
GolfGenius::Event.fetch("event_id")
```

**List parameters (filters)** — Per the API. Only these resources support list; filters below.

| Resource   | List params |
| ---------- | ----------- |
| Season     | `:page`, `:api_key` only (no filters). |
| Category   | `:page`, `:api_key` only (no filters). |
| Directory  | `:page`, `:api_key` only (no filters). |
| Event      | `:directory` / `:directory_id`, `:season` / `:season_id`, `:category` / `:category_id`, `:archived`, `:page`, `:api_key`. Pass resource objects or ids. **Default: non-archived only.** Use `archived: true` for archived-only. |

**Event nested data** (roster, rounds, courses, tournaments)

```ruby
GolfGenius::Event.roster("event_id", photo: true)   # :photo, :page
GolfGenius::Event.rounds("event_id")
GolfGenius::Event.courses("event_id")
GolfGenius::Event.tournaments("event_id", "round_id")
```

**Pagination**

```ruby
# list() already fetches all pages; for streaming use:
GolfGenius::Event.auto_paging_each(directory: dir) { |e| puts e.name }
# Or list_all (same as list() when no page: is passed)
GolfGenius::Event.list_all(season: season)
```

**Client (multiple API keys)**

```ruby
client = GolfGenius::Client.new(api_key: "key")
client.seasons.list
client.events.list(directory: dir)
client.events.fetch("event_id")
client.events.roster("event_id")
```

**Attributes**

```ruby
dir = GolfGenius::Directory.list.first
dir.id
dir.name
dir.event_count
dir.all_events
```

**Errors**

```ruby
GolfGenius::NotFoundError
GolfGenius::AuthenticationError
GolfGenius::RateLimitError
GolfGenius::GolfGeniusError  # base
```

**Environment (interrogate in console)**

```ruby
GolfGenius.env              # => #<GolfGenius::Environment production base_url="...">
GolfGenius.env.production?  # => true
GolfGenius.env.staging?    # => false
GolfGenius.env.custom?     # => false when production or staging
GolfGenius.env.to_s         # => "production" | "staging" | "custom"
```

**Debug (log raw requests)**

```ruby
GolfGenius.debug = true   # logs each request (method + full URL) and response to $stdout
# Or: GolfGenius.logger = Logger.new($stdout); GolfGenius.log_level = :debug
```

The API key is never logged or shown in `inspect`; it is only visible when you explicitly call `GolfGenius.api_key`.

## Development

```bash
bundle install
bin/console   # then reload! after editing lib/
bundle exec rake test
```

- [QUICKSTART.md](QUICKSTART.md) – example-focused guide
- [RAILS_SETUP.md](RAILS_SETUP.md) – Rails integration
- [API docs](https://www.golfgenius.com/api/v2/docs) (staging: https://ggstest.com)

## License

MIT
