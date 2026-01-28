# Golf Genius Ruby - Quick Start Guide

Get up and running with the Golf Genius Ruby gem in minutes.

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
event = GolfGenius::Event.retrieve('event_id')

puts "Event: #{event.name}"
puts "Date: #{event.date}"
puts "Location: #{event.location}"
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

## Using the Client Pattern

For applications that need to use multiple API keys or prefer an instance-based approach:

```ruby
# Create a client with specific API key
client = GolfGenius::Client.new(api_key: 'your_api_key')

# Use the client to access resources
seasons = client.seasons.list
events = client.events.list(page: 1)
event = client.events.retrieve('event_id')
roster = client.events.roster('event_id')
```

## Error Handling

```ruby
begin
  event = GolfGenius::Event.retrieve('invalid_id')
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

Run with real API (requires GOLF_GENIUS_API_KEY environment variable):

```bash
export GOLF_GENIUS_API_KEY='your_api_key'
bundle exec rake test
```

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
event = GolfGenius::Event.retrieve(event_id)
roster = GolfGenius::Event.roster(event_id)
rounds = GolfGenius::Event.rounds(event_id)
courses = GolfGenius::Event.courses(event_id)

# Get tournament data for a specific round
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

## Accessing Attributes

All resources return Ruby objects with attribute accessors:

```ruby
season = GolfGenius::Season.retrieve('season_id')
season.id        # => "123"
season.name      # => "2026 Season"
season.current   # => true

# Convert to hash
season.to_h      # => {:id=>"123", :name=>"2026 Season", :current=>true}
```

## Need Help?

- Check the [README.md](README.md) for comprehensive documentation
- Review the [examples/](examples/) directory for complete working examples
- Run the examples with your API key to see the gem in action
- Read the [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) for technical details

## API Reference

### Resources

- `GolfGenius::Season` - List and retrieve seasons
  - `.list()` - Get all seasons
  - `.retrieve(id)` - Get a specific season

- `GolfGenius::Category` - List and retrieve categories
  - `.list()` - Get all categories
  - `.retrieve(id)` - Get a specific category

- `GolfGenius::Directory` - List and retrieve directories
  - `.list()` - Get all directories
  - `.retrieve(id)` - Get a specific directory

- `GolfGenius::Event` - Comprehensive event access
  - `.list(params)` - Get events with optional filters
  - `.retrieve(id)` - Get a specific event
  - `.roster(event_id, params)` - Get event roster
  - `.rounds(event_id)` - Get event rounds
  - `.courses(event_id)` - Get event courses
  - `.tournaments(event_id, round_id)` - Get round tournaments

### Configuration

- `GolfGenius.api_key` - Set/get API key
- `GolfGenius.base_url` - Set/get base URL
- `GolfGenius.logger` - Set/get logger
- `GolfGenius.log_level` - Set/get log level

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

Ready to start building? Just set your API key and start making requests!
