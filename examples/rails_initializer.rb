# frozen_string_literal: true

# Rails Initializer Example
# Place this file in: config/initializers/golf_genius.rb
#
# Add to Gemfile: gem 'golf-genius'

# Option 1: Simple direct assignment (recommended for most cases)
GolfGenius.api_key = ENV["GOLF_GENIUS_API_KEY"]

# Option 2: Using the configure block (recommended for multiple settings)
GolfGenius.configure do |config|
  config.api_key = ENV["GOLF_GENIUS_API_KEY"]
  config.base_url = ENV.fetch("GOLF_GENIUS_BASE_URL", "https://www.golfgenius.com")
  config.open_timeout = 30
  config.read_timeout = 80

  # Optional: Configure logging (useful in development)
  if Rails.env.development?
    config.logger = Rails.logger
    config.log_level = :debug
  end
end

# After this initializer runs, the API key is available globally
# throughout your Rails application:
#
# # In any controller, service, model, job, etc:
# seasons = GolfGenius::Season.list
# events = GolfGenius::Event.list(season_id: season.id)
