#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "golf_genius"

# Using the client pattern (useful for multiple API keys)
# See: https://www.golfgenius.com/api/v2/docs
client = GolfGenius::Client.new(api_key: ENV["GOLF_GENIUS_API_KEY"])

puts "=== Golf Genius Ruby Gem - Client Usage ==="
puts "API Documentation: #{GolfGenius::API_DOCS_URL}"
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
  event = client.events.fetch(event_id)
  puts "Event: #{event.name}"

  puts "\nFetching event roster..."
  roster = client.events.roster(event_id)
  puts "Roster size: #{roster.count}"

  puts "\nFetching event rounds..."
  rounds = client.events.rounds(event_id)
  puts "Rounds: #{rounds.count}"

  puts "\nFetching event courses..."
  courses = client.events.courses(event_id)
  puts "Courses: #{courses.count}"

  # Get tournaments for first round
  if rounds.any?
    round_id = rounds.first.id
    puts "\nFetching tournaments for round #{round_id}..."
    tournaments = client.events.tournaments(event_id, round_id)
    puts "Tournaments: #{tournaments.count}"
  end
end

# Example: Auto-paging through all events
puts "\n=== Auto-Paging Example ==="
puts "Iterating through all events..."

count = 0
client.events.auto_paging_each(page: 1) do |event|
  count += 1
  puts "  #{count}. #{event.name}"
  break if count >= 10 # Limit for demo
end

puts "Processed #{count} events (limited to 10 for demo)"

# Example: Multiple clients with different API keys
puts "\n=== Multiple Clients Example ==="
puts "You can create multiple clients with different API keys:"
puts <<~CODE
  client_org1 = GolfGenius::Client.new(api_key: 'key_for_org_1')
  client_org2 = GolfGenius::Client.new(api_key: 'key_for_org_2')

  # Each client uses its own API key
  org1_events = client_org1.events.list
  org2_events = client_org2.events.list
CODE
