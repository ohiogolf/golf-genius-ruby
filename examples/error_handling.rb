#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "golf_genius"

GolfGenius.api_key = ENV["GOLF_GENIUS_API_KEY"]

puts "=== Golf Genius Ruby Gem - Error Handling ==="
puts

# Example 1: Handling NotFoundError
puts "1. Attempting to retrieve non-existent event..."
begin
  event = GolfGenius::Event.retrieve("invalid_event_id")
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
  events = GolfGenius::Event.list
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
  events = GolfGenius::Event.list
rescue GolfGenius::ConnectionError => e
  puts "Error: Connection failed"
  puts "Message: #{e.message}"
ensure
  GolfGenius.base_url = old_url
end
puts

# Example 4: Generic error handling
puts "4. Generic error handling pattern..."
begin
  seasons = GolfGenius::Season.list
  puts "Successfully retrieved #{seasons.count} seasons"
rescue GolfGenius::GolfGeniusError => e
  puts "API Error occurred:"
  puts "  Status: #{e.http_status}"
  puts "  Message: #{e.message}"
  puts "  Request ID: #{e.request_id}" if e.request_id
end
