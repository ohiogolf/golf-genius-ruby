# Golf Genius Ruby - Quick Start Guide

Get up and running with the Golf Genius Ruby gem in minutes.

**📖 [Official API Documentation](https://www.golfgenius.com/api/v2/docs)**

## Installation

### Option 1: Install from Source (Current)

```bash
cd golf-genius-ruby
bundle install
bundle exec rake build
gem install pkg/golf-genius-0.1.0.gem
```

### Option 2: Add to Gemfile (After Publishing)

```ruby
gem 'golf-genius'
```

Then run:
```bash
bundle install
```

## Basic Setup

```ruby
require 'golf_genius'

# Configure your API key
GolfGenius.api_key = 'your_api_key_here'

# Or use environment variable
GolfGenius.api_key = ENV['GOLF_GENIUS_API_KEY']
```

## Quick Examples

### List All Seasons

```ruby
seasons = GolfGenius::Season.list

seasons.each do |season|
  puts "#{season.name} - Current: #{season.current}"
end
```

### Get Events with Filters

```ruby
# List events from a specific season
events = GolfGenius::Event.list(
  page: 1,
  season_id: 'your_season_id',
  archived: false
)

events.each do |event|
  puts "#{event.name} - #{event.type}"
end
```

### Get Event Details

```ruby
# Get full event details
event = GolfGenius::Event.fetch('event_id')

puts "Event: #{event.name}"
puts "Date: #{event.date}"
puts "Location: #{event.location}"

# Access nested objects
puts "Season: #{event.season.name}"
puts "Category: #{event.category.name}"
```

### Get Event Roster

```ruby
roster = GolfGenius::Event.roster('event_id', photo: true)

roster.each do |player|
  puts "#{player.name} - Handicap: #{player.handicap}"
end
```

### Get Event Rounds

```ruby
rounds = GolfGenius::Event.rounds('event_id')

rounds.each do |round|
  puts "Round #{round.number}: #{round.date}"
end
```

### Auto-Pagination

```ruby
# Iterate through ALL events automatically
GolfGenius::Event.auto_paging_each(season_id: 'season_123') do |event|
  puts event.name
end

# Or get all as an array
all_events = GolfGenius::Event.list_all(season_id: 'season_123')
```

## Using the Client Pattern

For applications that need to use multiple API keys or prefer an instance-based approach:

```ruby
# Create a client with specific API key
client = GolfGenius::Client.new(api_key: 'your_api_key')

# Use the client to access resources
seasons = client.seasons.list
events = client.events.list(page: 1)
event = client.events.fetch('event_id')
roster = client.events.roster('event_id')

# Auto-pagination works too
client.events.auto_paging_each do |event|
  process(event)
end
```

## Error Handling

```ruby
begin
  event = GolfGenius::Event.fetch('invalid_id')
rescue GolfGenius::NotFoundError => e
  puts "Event not found: #{e.message}"
rescue GolfGenius::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue GolfGenius::RateLimitError => e
  puts "Rate limit exceeded: #{e.message}"
rescue GolfGenius::GolfGeniusError => e
  puts "API error: #{e.message} (Status: #{e.http_status})"
end
```

## Serialization

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

## Advanced Configuration

```ruby
GolfGenius.configure do |config|
  config.api_key = 'your_api_key'
  config.base_url = 'https://www.golfgenius.com'  # Default
  config.open_timeout = 30                        # Default
  config.read_timeout = 80                        # Default

  # Enable logging
  config.logger = Logger.new(STDOUT)
  config.log_level = :info
end
```

## Testing

Run the test suite:

```bash
bundle exec rake test
```

The test suite uses WebMock stubs, so no API key is required for testing.

## Examples

Three complete examples are included:

```bash
# Basic usage of all resources
ruby examples/basic_usage.rb

# Using the client pattern
ruby examples/client_usage.rb

# Error handling patterns
ruby examples/error_handling.rb
```

## Common Patterns

### Iterating Through All Resources

```ruby
# Get all categories
categories = GolfGenius::Category.list
categories.each { |cat| puts cat.name }

# Get all directories
directories = GolfGenius::Directory.list
directories.each { |dir| puts dir.name }
```

### Working with Event Data

```ruby
event_id = 'your_event_id'

# Get comprehensive event data
event = GolfGenius::Event.fetch(event_id)
roster = GolfGenius::Event.roster(event_id)
rounds = GolfGenius::Event.rounds(event_id)
courses = GolfGenius::Event.courses(event_id)

# Get tournament data for a specific round
round = rounds.first
tournaments = GolfGenius::Event.tournaments(event_id, round.id)
```

### Filtering Events

```ruby
# Events from current season only
current_season = GolfGenius::Season.list.find(&:current)
events = GolfGenius::Event.list(season_id: current_season.id)

# Events from specific category
category = GolfGenius::Category.list.first
events = GolfGenius::Event.list(category_id: category.id)

# Exclude archived events
events = GolfGenius::Event.list(archived: false)
```

## API Reference

### Resources

- `GolfGenius::Season` - List and fetch seasons
  - `.list()` - Get all seasons
  - `.fetch(id)` - Get a specific season
  - `.auto_paging_each { }` - Iterate through all pages
  - `.list_all()` - Get all as array

- `GolfGenius::Category` - List and fetch categories
  - `.list()` - Get all categories
  - `.fetch(id)` - Get a specific category

- `GolfGenius::Directory` - List and fetch directories
  - `.list()` - Get all directories
  - `.fetch(id)` - Get a specific directory

- `GolfGenius::Event` - Comprehensive event access
  - `.list(params)` - Get events with optional filters
  - `.fetch(id)` - Get a specific event
  - `.roster(event_id, params)` - Get event roster
  - `.rounds(event_id)` - Get event rounds
  - `.courses(event_id)` - Get event courses
  - `.tournaments(event_id, round_id)` - Get round tournaments
  - `.auto_paging_each(params) { }` - Iterate through all pages
  - `.list_all(params)` - Get all as array

### Configuration

- `GolfGenius.api_key` - Set/get API key
- `GolfGenius.base_url` - Set/get base URL
- `GolfGenius.logger` - Set/get logger
- `GolfGenius.log_level` - Set/get log level
- `GolfGenius.reset_configuration!` - Reset to defaults

### Error Classes

- `GolfGenius::GolfGeniusError` - Base error
- `GolfGenius::AuthenticationError` - 401/403 errors
- `GolfGenius::NotFoundError` - 404 errors
- `GolfGenius::ValidationError` - 422 errors
- `GolfGenius::RateLimitError` - 429 errors
- `GolfGenius::ServerError` - 5xx errors
- `GolfGenius::ConnectionError` - Network errors
- `GolfGenius::ConfigurationError` - Config errors

---

**Need Help?**

- Check the [README.md](README.md) for comprehensive documentation
- Review the [examples/](examples/) directory for complete working examples
- Read the [Golf Genius API Documentation](https://www.golfgenius.com/api/v2/docs)
