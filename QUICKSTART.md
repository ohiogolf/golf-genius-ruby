# Quick Start

[API docs](https://www.golfgenius.com/api/v2/docs) · Staging: **ggstest.com** — set `GOLF_GENIUS_ENV=staging` (or `GOLF_GENIUS_BASE_URL`) to use it globally.

## Install & configure

```ruby
# Gemfile
gem "golf-genius", github: "ohiogolf/golf-genius-ruby"
```

```bash
bundle install
```

```ruby
require "golf_genius"
GolfGenius.api_key = ENV["GOLF_GENIUS_API_KEY"]
```

## Examples

**List and inspect**

```ruby
GolfGenius::Season.list
GolfGenius::Category.list
GolfGenius::Directory.list
GolfGenius::Directory.list.first.name
```

**Fetch one**

```ruby
GolfGenius::Season.fetch("season_id")
GolfGenius::Directory.fetch("directory_id")
GolfGenius::Event.fetch("event_id")
```

**Events with filters** (pass objects or ids; `list()` fetches all pages by default)

```ruby
dirs = GolfGenius::Directory.list
GolfGenius::Event.list(directory: dirs.last)   # all events in that directory (non-archived only by default)
GolfGenius::Event.list(page: 1, directory: dirs.last)  # first page only
GolfGenius::Event.list(season: season, archived: false)
GolfGenius::Event.list(directory: dir, archived: true) # archived events only
```

Filters: `:directory`, `:season`, `:category` (or `_id` variants); `:archived` — default is non-archived only.

**Event nested data**

```ruby
GolfGenius::Event.roster("event_id", photo: true)
GolfGenius::Event.rounds("event_id")
GolfGenius::Event.courses("event_id")
GolfGenius::Event.tournaments("event_id", "round_id")
```

**Pagination**

```ruby
GolfGenius::Event.auto_paging_each(directory: dir) { |e| puts e.name }
GolfGenius::Event.list_all(season: season)
```

**Client**

```ruby
client = GolfGenius::Client.new(api_key: "key")
client.directories.list
client.events.list(directory: client.directories.list.last)
client.events.fetch("event_id")
```

## Console (development)

```bash
bin/console
```

- **`reload!`** – re-load the gem after editing `lib/` (no restart).
- **`table(collection)`** – print a list of resources as a table, e.g. `table(GolfGenius::Directory.list)`.

## Errors

```ruby
rescue GolfGenius::NotFoundError, GolfGenius::AuthenticationError, GolfGenius::RateLimitError => e
  puts e.message
  puts e.http_status
end
```

## More

- [README](README.md) – full usage and options
- [RAILS_SETUP.md](RAILS_SETUP.md) – Rails
- [examples/](examples/) – runnable scripts
