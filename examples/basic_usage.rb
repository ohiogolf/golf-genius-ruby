#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "golf_genius"

# Configure with your API key
# See: https://www.golfgenius.com/api/v2/docs
GolfGenius.api_key = ENV["GOLF_GENIUS_API_KEY"] || "your_api_key_here"

# Enable logging (optional)
require "logger"
GolfGenius.logger = Logger.new($stdout)
GolfGenius.log_level = :info

puts "=== Golf Genius Ruby Gem - Basic Usage ==="
puts "API Documentation: #{GolfGenius::API_DOCS_URL}"
puts

# List seasons
puts "Fetching seasons..."
seasons = GolfGenius::Season.list
puts "Found #{seasons.count} season(s)"
seasons.each do |season|
  puts "  - #{season.name} (ID: #{season.id}, Current: #{season.current})"
end
puts

# List categories
puts "Fetching categories..."
categories = GolfGenius::Category.list
puts "Found #{categories.count} category(ies)"
categories.each do |category|
  puts "  - #{category.name} (ID: #{category.id}, Events: #{category.event_count})"
end
puts

# List directories
puts "Fetching directories..."
directories = GolfGenius::Directory.list
puts "Found #{directories.count} directory(ies)"
directories.each do |directory|
  puts "  - #{directory.name} (ID: #{directory.id}, Events: #{directory.event_count})"
end
puts

# List events
puts "Fetching events (page 1)..."
events = GolfGenius::Event.list(page: 1)
puts "Found #{events.count} event(s)"
events.first(5).each do |event|
  puts "  - #{event.name} (ID: #{event.id}, Type: #{event.type})"
end
puts

# Get details for first event (if available)
if events.any?
  event = events.first
  puts "Getting details for: #{event.name}"

  # Fetch full event details
  full_event = GolfGenius::Event.fetch(event.id)
  puts "  Type: #{full_event.type}"
  puts "  Date: #{full_event.date}" if full_event.key?(:date)

  # Access nested objects
  puts "  Season: #{full_event.season.name}" if full_event.key?(:season)

  puts "  Category: #{full_event.category.name}" if full_event.key?(:category)

  # Get event roster
  puts "\nFetching roster..."
  roster = GolfGenius::Event.roster(event.id)
  puts "  Roster size: #{roster.count}"
  roster.first(3).each do |player|
    puts "    - #{player.name} (Handicap: #{player.handicap})" if player.key?(:name)
  end

  # Get event rounds
  puts "\nFetching rounds..."
  rounds = GolfGenius::Event.rounds(event.id)
  puts "  Number of rounds: #{rounds.count}"
  rounds.each do |round|
    puts "    - Round #{round.number}: #{round.date}" if round.key?(:number)
  end

  # Get event courses
  puts "\nFetching courses..."
  courses = GolfGenius::Event.courses(event.id)
  puts "  Number of courses/tees: #{courses.count}"
  courses.each do |course|
    puts "    - #{course.name} (#{course.tee})" if course.key?(:name)
  end
end

puts "\n=== Serialization Example ==="
if events.any?
  event = events.first

  # Convert to hash
  hash = event.to_h
  puts "Event as hash: #{hash.inspect}"

  # Convert to JSON
  json = event.to_json
  puts "Event as JSON: #{json}"
end
