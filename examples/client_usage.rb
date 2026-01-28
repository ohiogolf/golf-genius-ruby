#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "golf_genius"

# Using the client pattern (useful for multiple API keys)
client = GolfGenius::Client.new(api_key: ENV["GOLF_GENIUS_API_KEY"])

puts "=== Golf Genius Ruby Gem - Client Usage ==="
puts

# Access resources through the client
puts "Fetching seasons..."
seasons = client.seasons.list
puts "Found #{seasons.count} season(s)"

puts "\nFetching categories..."
categories = client.categories.list
puts "Found #{categories.count} category(ies)"

puts "\nFetching directories..."
directories = client.directories.list
puts "Found #{directories.count} directory(ies)"

puts "\nFetching events..."
events = client.events.list(page: 1)
puts "Found #{events.count} event(s)"

if events.any?
  event_id = events.first.id

  puts "\nFetching event details..."
  event = client.events.retrieve(event_id)
  puts "Event: #{event.name}"

  puts "\nFetching event roster..."
  roster = client.events.roster(event_id)
  puts "Roster size: #{roster.count}"
end
