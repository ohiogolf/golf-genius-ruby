#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "golf_genius"

# See: https://www.golfgenius.com/api/v2/docs
GolfGenius.api_key = ENV["GOLF_GENIUS_API_KEY"]

puts "=== Golf Genius Ruby Gem - Error Handling ==="
puts "API Documentation: #{GolfGenius::API_DOCS_URL}"
puts

# Example 1: Handling NotFoundError
puts "1. Attempting to fetch non-existent event..."
begin
  event = GolfGenius::Event.fetch("invalid_event_id")
  puts "Event found: #{event.name}"
rescue GolfGenius::NotFoundError => e
  puts "Error: Event not found (#{e.http_status})"
  puts "Message: #{e.message}"
end
puts

# Example 2: Handling AuthenticationError
puts "2. Attempting to use invalid API key..."
begin
  old_key = GolfGenius.api_key
  GolfGenius.api_key = "invalid_key"
  GolfGenius::Event.list
rescue GolfGenius::AuthenticationError => e
  puts "Error: Authentication failed (#{e.http_status})"
  puts "Message: #{e.message}"
ensure
  GolfGenius.api_key = old_key
end
puts

# Example 3: Handling ConnectionError
puts "3. Attempting to connect to invalid host..."
begin
  old_url = GolfGenius.base_url
  GolfGenius.base_url = "https://invalid-host-that-does-not-exist.example.com"
  GolfGenius::Event.list
rescue GolfGenius::ConnectionError => e
  puts "Error: Connection failed"
  puts "Message: #{e.message}"
ensure
  GolfGenius.base_url = old_url
end
puts

# Example 4: Handling ConfigurationError
puts "4. Attempting to make request without API key..."
begin
  GolfGenius.reset_configuration!
  GolfGenius::Event.list
rescue GolfGenius::ConfigurationError => e
  puts "Error: Configuration error"
  puts "Message: #{e.message}"
ensure
  GolfGenius.api_key = ENV["GOLF_GENIUS_API_KEY"]
end
puts

# Example 5: Generic error handling
puts "5. Generic error handling pattern..."
begin
  seasons = GolfGenius::Season.list
  puts "Successfully retrieved #{seasons.count} seasons"
rescue GolfGenius::NotFoundError => e
  puts "Resource not found: #{e.message}"
rescue GolfGenius::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue GolfGenius::RateLimitError => e
  puts "Rate limit exceeded, retry after: #{e.http_headers["Retry-After"]}"
rescue GolfGenius::ValidationError => e
  puts "Invalid request: #{e.message}"
rescue GolfGenius::ServerError => e
  puts "Server error: #{e.message}"
rescue GolfGenius::ConnectionError => e
  puts "Network error: #{e.message}"
rescue GolfGenius::GolfGeniusError => e
  puts "API Error occurred:"
  puts "  Status: #{e.http_status}"
  puts "  Message: #{e.message}"
  puts "  Request ID: #{e.request_id}" if e.request_id
end
puts

# Example 6: Error attributes
puts "6. Accessing error attributes..."
begin
  GolfGenius::Event.fetch("nonexistent")
rescue GolfGenius::GolfGeniusError => e
  puts "Error class: #{e.class.name}"
  puts "HTTP Status: #{e.http_status}"
  puts "HTTP Body: #{e.http_body.inspect}"
  puts "HTTP Headers: #{e.http_headers.keys.join(", ")}" if e.http_headers.any?
  puts "Request ID: #{e.request_id || "N/A"}"
  puts "Full message: #{e}"
end
