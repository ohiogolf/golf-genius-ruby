#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "golf_genius"

# Configure with your API key
GolfGenius.api_key = ENV["GOLF_GENIUS_API_KEY"] || "your_api_key_here"

# Enable logging (optional)
require "logger"
GolfGenius.logger = Logger.new(STDOUT)
GolfGenius.log_level = :info

puts "=== Golf Genius Ruby Gem - Basic Usage ==="
puts

# List seasons
puts "Fetching seasons..."
seasons = GolfGenius::Season.list
puts "Found #{seasons.count} season(s)"
seasons.each do |season|
  puts "  - #{season.name} (ID: #{season.id})"
end
puts

# List categories
puts "Fetching categories..."
categories = GolfGenius::Category.list
puts "Found #{categories.count} category(ies)"
categories.each do |category|
  puts "  - #{category.name} (ID: #{category.id})"
end
puts

# List directories
puts "Fetching directories..."
directories = GolfGenius::Directory.list
puts "Found #{directories.count} directory(ies)"
directories.each do |directory|
  puts "  - #{directory.name} (ID: #{directory.id})"
end
puts

# List events
puts "Fetching events (page 1)..."
events = GolfGenius::Event.list(page: 1)
puts "Found #{events.count} event(s)"
events.first(5).each do |event|
  puts "  - #{event.name} (ID: #{event.id})"
end
puts

# Get details for first event (if available)
if events.any?
  event = events.first
  puts "Getting details for: #{event.name}"

  # Retrieve full event details
  full_event = GolfGenius::Event.retrieve(event.id)
  puts "Event type: #{full_event.type}"

  # Get event roster
  puts "Fetching roster..."
  roster = GolfGenius::Event.roster(event.id)
  puts "Roster size: #{roster.count}"

  # Get event rounds
  puts "Fetching rounds..."
  rounds = GolfGenius::Event.rounds(event.id)
  puts "Number of rounds: #{rounds.count}"
end
