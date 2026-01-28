# Golf Genius Ruby - Rails Setup Guide

## Installation

Add to your Gemfile:

```ruby
gem 'golf-genius'
```

Then run:
```bash
bundle install
```

**That's it!** Rails will automatically load the gem via Bundler. No manual `require` statements needed.

## Configuration

### Step 1: Add API Key to Credentials

#### Rails 5.2+ with encrypted credentials:

```bash
EDITOR=vim rails credentials:edit
```

Add your API key:
```yaml
golf_genius:
  api_key: your_api_key_here
```

#### Or use environment variables:

Add to `.env` (with dotenv-rails gem):
```bash
GOLF_GENIUS_API_KEY=your_api_key_here
```

Or set in your shell/deployment environment:
```bash
export GOLF_GENIUS_API_KEY=your_api_key_here
```

### Step 2: Create Initializer

Create `config/initializers/golf_genius.rb`:

#### Simple Version (Environment Variable)

```ruby
# config/initializers/golf_genius.rb
GolfGenius.api_key = ENV['GOLF_GENIUS_API_KEY']
```

#### Using Rails Credentials

```ruby
# config/initializers/golf_genius.rb
GolfGenius.api_key = Rails.application.credentials.dig(:golf_genius, :api_key)
```

#### Full Configuration with Logging

```ruby
# config/initializers/golf_genius.rb
GolfGenius.configure do |config|
  config.api_key = ENV['GOLF_GENIUS_API_KEY']

  # Optional: Customize base URL (usually not needed)
  config.base_url = 'https://www.golfgenius.com'

  # Optional: Customize timeouts
  config.open_timeout = 30  # seconds
  config.read_timeout = 80  # seconds

  # Optional: Enable logging in development
  if Rails.env.development?
    config.logger = Rails.logger
    config.log_level = :debug
  end
end
```

## Usage in Rails

### In Controllers

```ruby
class EventsController < ApplicationController
  def index
    # No need to pass API key - it's configured globally
    @seasons = GolfGenius::Season.list
    @events = GolfGenius::Event.list(page: params[:page] || 1)
  end

  def show
    @event = GolfGenius::Event.retrieve(params[:id])
    @roster = GolfGenius::Event.roster(params[:id])
    @rounds = GolfGenius::Event.rounds(params[:id])
  end
end
```

### In Models

```ruby
class Tournament < ApplicationRecord
  def sync_from_golf_genius
    event = GolfGenius::Event.retrieve(golf_genius_id)

    update(
      name: event.name,
      start_date: event.start_date,
      location: event.location
    )

    sync_roster(event)
  end

  private

  def sync_roster(event)
    roster = GolfGenius::Event.roster(event.id)

    roster.each do |player|
      participants.find_or_create_by(
        golf_genius_id: player.id
      ).update(
        name: player.name,
        handicap: player.handicap
      )
    end
  end
end
```

### In Background Jobs

```ruby
class SyncGolfGeniusEventsJob < ApplicationJob
  queue_as :default

  def perform(season_id)
    # Global configuration is available in background jobs
    events = GolfGenius::Event.list(season_id: season_id)

    events.each do |event|
      Tournament.find_or_create_by(
        golf_genius_id: event.id
      ).sync_from_golf_genius
    end
  end
end
```

### In Services

```ruby
class GolfGeniusSync
  def sync_season(season_id)
    events = GolfGenius::Event.list(season_id: season_id)

    events.each do |event|
      sync_event(event)
    end
  end

  private

  def sync_event(event)
    full_event = GolfGenius::Event.retrieve(event.id)
    roster = GolfGenius::Event.roster(event.id)
    rounds = GolfGenius::Event.rounds(event.id)

    # ... sync logic
  end
end
```

### In Rails Console

```bash
rails console
```

```ruby
# The gem is auto-loaded by Rails (no require needed)
# API key is already configured from initializer
seasons = GolfGenius::Season.list
# => [#<GolfGenius::Season...>, ...]

current_season = seasons.find(&:current)
# => #<GolfGenius::Season id="123", name="2026 Season", current=true>

events = GolfGenius::Event.list(season_id: current_season.id)
# => [#<GolfGenius::Event...>, ...]
```

## Testing in Rails

### RSpec Setup

```ruby
# spec/rails_helper.rb or spec/support/golf_genius.rb
RSpec.configure do |config|
  config.before(:suite) do
    # Use a test API key or stub requests
    GolfGenius.api_key = ENV['GOLF_GENIUS_TEST_API_KEY'] || 'test_key'
  end
end
```

### With VCR (Recommended)

```ruby
# Gemfile
group :test do
  gem 'vcr'
  gem 'webmock'
end
```

```ruby
# spec/support/vcr.rb
VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.filter_sensitive_data('<GOLF_GENIUS_API_KEY>') do
    ENV['GOLF_GENIUS_API_KEY']
  end
end
```

```ruby
# spec/services/golf_genius_sync_spec.rb
require 'rails_helper'

RSpec.describe GolfGeniusSync do
  describe '#sync_season' do
    it 'syncs events from Golf Genius', :vcr do
      service = GolfGeniusSync.new
      service.sync_season('season_123')

      expect(Tournament.count).to be > 0
    end
  end
end
```

### With WebMock Stubs

```ruby
# spec/services/golf_genius_sync_spec.rb
require 'rails_helper'

RSpec.describe GolfGeniusSync do
  before do
    stub_request(:get, %r{golfgenius.com/api_v2/.+/events})
      .to_return(
        status: 200,
        body: [{ id: '123', name: 'Test Event' }].to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  it 'syncs events' do
    service = GolfGeniusSync.new
    service.sync_season('season_123')

    expect(Tournament.count).to eq(1)
  end
end
```

## Error Handling in Rails

```ruby
class EventsController < ApplicationController
  rescue_from GolfGenius::GolfGeniusError, with: :handle_golf_genius_error

  def show
    @event = GolfGenius::Event.retrieve(params[:id])
  rescue GolfGenius::NotFoundError
    render_not_found
  rescue GolfGenius::RateLimitError => e
    # Retry after the rate limit period
    retry_after = e.http_headers['Retry-After']
    render json: { error: 'Rate limit exceeded', retry_after: retry_after }, status: 429
  end

  private

  def handle_golf_genius_error(exception)
    Rails.logger.error "Golf Genius API Error: #{exception.message}"

    case exception
    when GolfGenius::AuthenticationError
      # API key issue - alert admins
      notify_admins_of_auth_failure
      render_server_error
    when GolfGenius::ServerError
      # Golf Genius is down - show maintenance message
      render_maintenance_message
    else
      render_server_error
    end
  end
end
```

## Caching (Recommended)

Since Golf Genius data doesn't change frequently, cache API responses:

```ruby
class EventsController < ApplicationController
  def index
    @seasons = Rails.cache.fetch('golf_genius/seasons', expires_in: 1.hour) do
      GolfGenius::Season.list
    end

    @events = Rails.cache.fetch("golf_genius/events/#{params[:season_id]}", expires_in: 5.minutes) do
      GolfGenius::Event.list(season_id: params[:season_id])
    end
  end

  def show
    @event = Rails.cache.fetch("golf_genius/event/#{params[:id]}", expires_in: 5.minutes) do
      GolfGenius::Event.retrieve(params[:id])
    end
  end
end
```

## Multi-Tenancy

If you need different API keys per tenant:

```ruby
# Don't use global configuration for multi-tenancy
# Instead, use client instances:

class EventsController < ApplicationController
  def index
    client = golf_genius_client
    @events = client.events.list
  end

  private

  def golf_genius_client
    # Get API key from current tenant/account
    api_key = current_account.golf_genius_api_key
    GolfGenius::Client.new(api_key: api_key)
  end
end
```

## Environment-Specific Configuration

```ruby
# config/initializers/golf_genius.rb
GolfGenius.configure do |config|
  case Rails.env
  when 'development', 'test'
    config.api_key = ENV['GOLF_GENIUS_TEST_API_KEY']
    config.logger = Rails.logger
    config.log_level = :debug
  when 'staging'
    config.api_key = ENV['GOLF_GENIUS_STAGING_API_KEY']
    config.logger = Rails.logger
    config.log_level = :info
  when 'production'
    config.api_key = ENV['GOLF_GENIUS_API_KEY']
    config.logger = Rails.logger
    config.log_level = :warn
  end
end
```

## Summary

✅ **Yes, you can set the API key globally in a Rails initializer!**

The gem is designed to work seamlessly with Rails:
- Set it once in `config/initializers/golf_genius.rb`
- Use it anywhere in your app (controllers, models, jobs, services)
- No need to pass the API key around
- Thread-safe for multi-threaded Rails servers
- Works with Rails console, background jobs, and tests

Simply add this to your initializer:
```ruby
GolfGenius.api_key = ENV['GOLF_GENIUS_API_KEY']
```

And you're ready to use the gem throughout your Rails application!
