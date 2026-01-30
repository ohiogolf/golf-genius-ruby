# frozen_string_literal: true

# API response fixtures for testing.
# These are based on expected Golf Genius API v2 response structures.
# See: https://www.golfgenius.com/api/v2/docs
module GolfGenius
  module TestFixtures
    # Sample seasons response
    SEASONS = [
      {
        "id" => "season_001",
        "name" => "2026 Season",
        "current" => true,
        "start_date" => "2026-01-01",
        "end_date" => "2026-12-31",
      },
      {
        "id" => "season_002",
        "name" => "2025 Season",
        "current" => false,
        "start_date" => "2025-01-01",
        "end_date" => "2025-12-31",
      },
    ].freeze

    SEASON = SEASONS.first.freeze

    # Sample categories response
    CATEGORIES = [
      {
        "id" => "cat_001",
        "name" => "Member Events",
        "color" => "#FF5733",
        "event_count" => 15,
        "archived" => false,
      },
      {
        "id" => "cat_002",
        "name" => "Guest Events",
        "color" => "#33FF57",
        "event_count" => 8,
        "archived" => false,
      },
    ].freeze

    CATEGORY = CATEGORIES.first.freeze

    # Sample directories response
    DIRECTORIES = [
      {
        "id" => "dir_001",
        "name" => "Main Directory",
        "event_count" => 25,
        "all_events" => false,
      },
      {
        "id" => "dir_002",
        "name" => "Archive Directory",
        "event_count" => 100,
        "all_events" => true,
      },
    ].freeze

    DIRECTORY = DIRECTORIES.first.freeze

    # Sample events response
    EVENTS = [
      {
        "id" => "event_001",
        "name" => "Spring Championship",
        "type" => "tournament",
        "date" => "2026-04-15",
        "location" => "Pine Valley Golf Club",
        "archived" => false,
        "season" => {
          "id" => "season_001",
          "name" => "2026 Season",
        },
        "category" => {
          "id" => "cat_001",
          "name" => "Member Events",
          "color" => "#FF5733",
        },
      },
      {
        "id" => "event_002",
        "name" => "Summer Outing",
        "type" => "outing",
        "date" => "2026-07-20",
        "location" => "Oakmont Country Club",
        "archived" => false,
        "season" => {
          "id" => "season_001",
          "name" => "2026 Season",
        },
        "category" => {
          "id" => "cat_002",
          "name" => "Guest Events",
          "color" => "#33FF57",
        },
      },
    ].freeze

    EVENT = EVENTS.first.freeze

    # Sample event roster response
    EVENT_ROSTER = [
      {
        "id" => "player_001",
        "name" => "John Smith",
        "email" => "john@example.com",
        "handicap" => 12.5,
        "tee" => "Blue",
        "photo_url" => "https://example.com/photos/john.jpg",
      },
      {
        "id" => "player_002",
        "name" => "Jane Doe",
        "email" => "jane@example.com",
        "handicap" => 8.2,
        "tee" => "White",
        "photo_url" => "https://example.com/photos/jane.jpg",
      },
      {
        "id" => "player_003",
        "name" => "Bob Wilson",
        "email" => "bob@example.com",
        "handicap" => 18.0,
        "tee" => "Blue",
        "photo_url" => nil,
      },
    ].freeze

    # Sample event rounds response
    EVENT_ROUNDS = [
      {
        "id" => "round_001",
        "number" => 1,
        "date" => "2026-04-15",
        "format" => "stroke_play",
        "status" => "completed",
      },
      {
        "id" => "round_002",
        "number" => 2,
        "date" => "2026-04-16",
        "format" => "stroke_play",
        "status" => "scheduled",
      },
    ].freeze

    # Sample event courses response
    EVENT_COURSES = [
      {
        "id" => "course_001",
        "name" => "Pine Valley - Championship",
        "tee" => "Blue",
        "rating" => 74.5,
        "slope" => 145,
        "par" => 72,
      },
      {
        "id" => "course_002",
        "name" => "Pine Valley - Championship",
        "tee" => "White",
        "rating" => 71.2,
        "slope" => 138,
        "par" => 72,
      },
    ].freeze

    # Sample tournaments response
    TOURNAMENTS = [
      {
        "id" => "tourn_001",
        "name" => "Flight A - Gross",
        "type" => "individual",
        "scoring" => "gross",
        "status" => "completed",
      },
      {
        "id" => "tourn_002",
        "name" => "Flight A - Net",
        "type" => "individual",
        "scoring" => "net",
        "status" => "completed",
      },
    ].freeze

    # Paginated events response (page 1 of 2)
    EVENTS_PAGE_1 = (1..25).map do |i|
      {
        "id" => "event_#{i.to_s.rjust(3, "0")}",
        "name" => "Event #{i}",
        "type" => "tournament",
        "date" => "2026-01-#{i.to_s.rjust(2, "0")}",
        "archived" => false,
      }
    end.freeze

    # Paginated events response (page 2 of 2)
    EVENTS_PAGE_2 = (26..30).map do |i|
      {
        "id" => "event_#{i.to_s.rjust(3, "0")}",
        "name" => "Event #{i}",
        "type" => "tournament",
        "date" => "2026-02-#{(i - 25).to_s.rjust(2, "0")}",
        "archived" => false,
      }
    end.freeze

    # Error responses
    ERROR_NOT_FOUND = {
      "error" => "Resource not found",
      "message" => "The requested resource could not be found",
    }.freeze

    ERROR_UNAUTHORIZED = {
      "error" => "Unauthorized",
      "message" => "Invalid or missing API key",
    }.freeze

    ERROR_VALIDATION = {
      "error" => "Validation failed",
      "message" => "Invalid parameters provided",
      "errors" => ["page must be a positive integer"],
    }.freeze

    ERROR_RATE_LIMIT = {
      "error" => "Rate limit exceeded",
      "message" => "Too many requests. Please retry after 60 seconds.",
    }.freeze

    ERROR_SERVER = {
      "error" => "Internal server error",
      "message" => "An unexpected error occurred",
    }.freeze
  end
end
