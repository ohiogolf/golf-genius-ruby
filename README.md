# Golf Genius Ruby

A Ruby library for accessing the Golf Genius API v2. This gem provides read-only access to seasons, categories, directories, and events.

## Documentation

- **[Golf Genius API Documentation](https://www.golfgenius.com/api/v2/docs)** - Official API reference

## Installation

### From GitHub (Recommended)

Add this line to your application's Gemfile:

```ruby
# Latest from main branch
gem "golf-genius", github: "ohiogolf/golf-genius-ruby"

# Or pin to a specific version tag
gem "golf-genius", github: "ohiogolf/golf-genius-ruby", tag: "v0.1.0"

# Or pin to a specific commit
gem "golf-genius", github: "ohiogolf/golf-genius-ruby", ref: "abc1234"
```

Then execute:

```bash
bundle install
```

### From RubyGems (Future)

Once published to RubyGems:

```ruby
gem "golf-genius"
```

## Usage

### Configuration

#### In a Ruby Script

```ruby
require 'golf_genius'  # Note: underscore (Ruby auto-converts from gem name 'golf-genius')

GolfGenius.api_key = 'your_api_key_here'
```

#### In Rails

No `require` needed! Just add the gem to your Gemfile and Rails will auto-load it:

```ruby
# Gemfile
gem 'golf-genius'
```

Then configure in an initializer:

```ruby
# config/initializers/golf_genius.rb
GolfGenius.api_key = ENV['GOLF_GENIUS_API_KEY']

# Or with full configuration:
GolfGenius.configure do |config|
  config.api_key = ENV['GOLF_GENIUS_API_KEY']
  config.logger = Rails.logger if Rails.env.development?
  config.log_level = :info
end
```

See [RAILS_SETUP.md](RAILS_SETUP.md) for a complete Rails integration guide.

### Using the Client

You can use the module-level methods or create a client instance:

```ruby
# Module-level usage
seasons = GolfGenius::Season.list
season = GolfGenius::Season.fetch('season_id')

# Client instance usage (useful for multiple API keys)
client = GolfGenius::Client.new(api_key: 'your_api_key')
seasons = client.seasons.list
season = client.seasons.fetch('season_id')
```

### Seasons

```ruby
# List all seasons
seasons = GolfGenius::Season.list

# Get a specific season
season = GolfGenius::Season.fetch('season_id')

# Access attributes
season.id
season.name
season.current
```

### Categories

```ruby
# List all categories
categories = GolfGenius::Category.list

# Get a specific category
category = GolfGenius::Category.fetch('category_id')

# Access attributes
category.id
category.name
category.color
category.event_count
category.archived
```

### Directories

```ruby
# List all directories
directories = GolfGenius::Directory.list

# Get a specific directory
directory = GolfGenius::Directory.fetch('directory_id')

# Access attributes
directory.id
directory.name
directory.event_count
directory.all_events
```

### Events

```ruby
# List events (with optional filters)
events = GolfGenius::Event.list(
  page: 1,
  season_id: 'season_id',
  category_id: 'category_id',
  directory_id: 'directory_id',
  archived: false
)

# Get a specific event
event = GolfGenius::Event.fetch('event_id')

# Get event roster
roster = GolfGenius::Event.roster('event_id', page: 1, photo: true)

# Get event rounds
rounds = GolfGenius::Event.rounds('event_id')

# Get event courses/tees
courses = GolfGenius::Event.courses('event_id')

# Get tournaments for a round
tournaments = GolfGenius::Event.tournaments('event_id', 'round_id')

# Access attributes
event.id
event.name
event.type

# Nested objects are automatically converted to Ruby objects
event.season.name      # Access nested season name
event.category.color   # Access nested category color

# Arrays of objects work too
event.participants.each do |participant|
  puts participant.name  # Each participant is a Ruby object
end
```

### Pagination

The gem provides automatic pagination support for list endpoints:

```ruby
# Iterate through all events across all pages
GolfGenius::Event.auto_paging_each(season_id: 'season_123') do |event|
  puts event.name
end

# Get all events as an array (use with caution on large datasets)
all_events = GolfGenius::Event.list_all(season_id: 'season_123')

# Works with the client too
client = GolfGenius::Client.new(api_key: 'your_key')
client.events.auto_paging_each do |event|
  process(event)
end
```

### Serialization

Objects can be easily serialized:

```ruby
event = GolfGenius::Event.fetch('event_id')

# Convert to hash (recursively converts nested objects)
hash = event.to_h

# Convert to JSON
json = event.to_json

# Check for attributes
event.key?(:name)  # => true
event[:name]       # => "Event Name"
```

### Error Handling

The gem raises specific errors for different API responses:

```ruby
begin
  event = GolfGenius::Event.fetch('invalid_id')
rescue GolfGenius::NotFoundError => e
  puts "Event not found: #{e.message}"
rescue GolfGenius::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue GolfGenius::RateLimitError => e
  puts "Rate limit exceeded: #{e.message}"
rescue GolfGenius::ServerError => e
  puts "Server error: #{e.message}"
rescue GolfGenius::GolfGeniusError => e
  puts "API error: #{e.message}"
  puts "HTTP Status: #{e.http_status}"
end
```

Available error classes:
- `GolfGenius::GolfGeniusError` - Base error class
- `GolfGenius::AuthenticationError` - Invalid or missing API key (401, 403)
- `GolfGenius::NotFoundError` - Resource not found (404)
- `GolfGenius::ValidationError` - Invalid request parameters (422)
- `GolfGenius::RateLimitError` - Rate limit exceeded (429)
- `GolfGenius::ServerError` - Server errors (5xx)
- `GolfGenius::ConnectionError` - Network errors
- `GolfGenius::ConfigurationError` - Configuration errors

### Using Custom API Keys

Pass an API key to individual calls or use the client:

```ruby
# Per-request API key
seasons = GolfGenius::Season.list(api_key: 'different_key')
season = GolfGenius::Season.fetch('season_id', api_key: 'different_key')

# Client with specific API key
client = GolfGenius::Client.new(api_key: 'org_specific_key')
seasons = client.seasons.list
```

## Development

After checking out the repo, run:

```bash
bundle install
```

To run tests:

```bash
bundle exec rake test
```

The test suite uses WebMock to stub API responses, so no API key is needed for testing.

To generate documentation:

```bash
bundle exec yard doc
bundle exec yard server
```

## Adding New Resources

Resources follow a consistent pattern. To add a new resource:

```ruby
# lib/golf_genius/resources/player.rb
module GolfGenius
  class Player < Resource
    # Explicit path - no magic!
    RESOURCE_PATH = "/players"

    extend APIOperations::List
    extend APIOperations::Fetch

    # Add nested resources if needed
    extend APIOperations::NestedResource
    nested_resource :scores, path: "/players/%{parent_id}/scores"
  end
end
```

Then add to `lib/golf_genius.rb`:

```ruby
require "golf_genius/resources/player"
```

And to the client if desired:

```ruby
def players
  @players ||= ResourceProxy.new(Player, @api_key)
end
```

## Resources

- [Golf Genius API Documentation](https://www.golfgenius.com/api/v2/docs)
- [GitHub Repository](https://github.com/ohiogolf/golf-genius-ruby)

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE).
