# Golf Genius Ruby

A Ruby library for accessing the Golf Genius API v2. This gem provides read-only access to seasons, categories, directories, and events.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'golf-genius'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install golf-genius
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

Then configure in an initializer (see Rails Configuration below).

Or configure with a block:

```ruby
GolfGenius.configure do |config|
  config.api_key = 'your_api_key_here'
  config.base_url = 'https://www.golfgenius.com' # optional, this is the default
  config.logger = Logger.new(STDOUT) # optional
  config.log_level = :info # optional
end
```

### Rails Configuration

The gem works seamlessly with Rails! Rails will automatically load the gem when you add it to your Gemfile (no manual `require` needed). Just create an initializer to set your API key globally:

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

After configuring in an initializer, the gem is ready to use anywhere in your Rails app (controllers, models, jobs, services) without passing the API key each time. See [RAILS_SETUP.md](RAILS_SETUP.md) for a complete Rails integration guide.
```

### Using the Client

You can use the module-level methods or create a client instance:

```ruby
# Module-level usage
seasons = GolfGenius::Season.list
season = GolfGenius::Season.retrieve('season_id')

# Client instance usage (useful for multiple API keys)
client = GolfGenius::Client.new(api_key: 'your_api_key')
seasons = client.seasons.list
season = client.seasons.retrieve('season_id')
```

### Seasons

```ruby
# List all seasons
seasons = GolfGenius::Season.list

# Get a specific season
season = GolfGenius::Season.retrieve('season_id')

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
category = GolfGenius::Category.retrieve('category_id')

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
directory = GolfGenius::Directory.retrieve('directory_id')

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
event = GolfGenius::Event.retrieve('event_id')

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

### Error Handling

The gem raises specific errors for different API responses:

```ruby
begin
  event = GolfGenius::Event.retrieve('invalid_id')
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

## Development

After checking out the repo, run:

```bash
bundle install
```

To run tests:

```bash
bundle exec rake test
```

To generate documentation:

```bash
bundle exec yard doc
bundle exec yard server
```

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE).
