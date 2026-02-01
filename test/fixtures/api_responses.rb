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

    # Sample event roster response (scalar values)
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

    # Sample event roster response (detailed handicap + tee)
    EVENT_ROSTER_WITH_DETAILS = [
      {
        "id" => "player_001",
        "name" => "John Smith",
        "email" => "john@example.com",
        "handicap" => {
          "handicap_network_id" => "123",
          "handicap_index" => "12.5",
          "nine_hole_handicap_index" => "",
        },
        "tee" => {
          "id" => "tee_001",
          "name" => "Blue",
          "abbreviation" => "BLUE",
          "nine_hole_course" => false,
          "created_at" => "2025-01-05 09:30:00 -0500",
          "updated_at" => "2025-02-10 12:45:00 -0500",
          "color" => "#0055AA",
          "course_id" => "course_001",
          "parent_id" => "course_001",
        },
        "photo_url" => "https://example.com/photos/john.jpg",
      },
      {
        "id" => "player_002",
        "name" => "Jane Doe",
        "email" => "jane@example.com",
        "handicap" => {
          "handicap_network_id" => "456",
          "handicap_index" => "8.2",
          "nine_hole_handicap_index" => "",
        },
        "tee" => {
          "id" => "tee_002",
          "name" => "White",
          "abbreviation" => "WHT",
          "nine_hole_course" => false,
          "created_at" => "2025-01-05 09:30:00 -0500",
          "updated_at" => "2025-02-10 12:45:00 -0500",
          "color" => "#E0E0E0",
          "course_id" => "course_001",
          "parent_id" => "course_001",
        },
        "photo_url" => "https://example.com/photos/jane.jpg",
      },
      {
        "id" => "player_003",
        "name" => "Bob Wilson",
        "email" => "bob@example.com",
        "handicap" => {
          "handicap_network_id" => "789",
          "handicap_index" => "18.0",
          "nine_hole_handicap_index" => "",
        },
        "tee" => {
          "id" => "tee_001",
          "name" => "Blue",
          "abbreviation" => "BLUE",
          "nine_hole_course" => false,
          "created_at" => "2025-01-05 09:30:00 -0500",
          "updated_at" => "2025-02-10 12:45:00 -0500",
          "color" => "#0055AA",
          "course_id" => "course_001",
          "parent_id" => "course_001",
        },
        "photo_url" => nil,
      },
    ].freeze

    # Sample event rounds response (API uses index for ordering)
    EVENT_ROUNDS = [
      {
        "id" => "round_001",
        "index" => 1,
        "number" => 1,
        "date" => "2026-04-15",
        "format" => "stroke_play",
        "status" => "completed",
      },
      {
        "id" => "round_002",
        "index" => 2,
        "number" => 2,
        "date" => "2026-04-16",
        "format" => "stroke_play",
        "status" => "scheduled",
      },
    ].freeze

    # Sample event divisions response (API returns [ { "division" => {...} } ])
    EVENT_DIVISIONS = [
      {
        "division" => {
          "id" => "2794531013441653808",
          "id_str" => "2794531013441653808",
          "event_id" => "2794531013441653805",
          "event_id_str" => "2794531013441653805",
          "name" => "Division Test",
          "status" => "not started",
          "position" => 0,
          "tee_times" => [
            { "time" => "8:10 AM", "starting_hole" => 1, "starting_hole_label" => "A" },
            { "time" => "8:15 AM", "starting_hole" => 1, "starting_hole_label" => "A" },
          ],
        },
      },
      {
        "division" => {
          "id" => "div_002",
          "name" => "Flight B",
          "event_id" => "2794531013441653805",
          "status" => "in progress",
          "position" => 1,
        },
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

    # Sample tournaments response (API wrapped)
    TOURNAMENTS_WRAPPED = TOURNAMENTS.map do |tournament|
      { "event" => tournament }
    end.freeze

    # Sample master roster response (API returns [ { "member" => {...} } ])
    MASTER_ROSTER = [
      {
        "member" => {
          "id" => "player_001",
          "name" => "John Smith",
          "email" => "john@example.com",
          "first_name" => "John",
          "last_name" => "Smith",
          "deleted" => false,
          "handicap" => {
            "handicap_network_id" => "123",
            "handicap_index" => "12.5",
            "nine_hole_handicap_index" => "",
          },
          "tee" => {
            "id" => "tee_001",
            "name" => "Blue",
            "abbreviation" => "BLUE",
            "nine_hole_course" => false,
            "created_at" => "2025-01-05 09:30:00 -0500",
            "updated_at" => "2025-02-10 12:45:00 -0500",
            "color" => "#0055AA",
            "course_id" => "course_001",
            "parent_id" => "course_001",
          },
          "custom_fields" => {
            "Affiliation" => "Pine Valley Golf Club",
            "Gender" => "M",
          },
        },
      },
      {
        "member" => {
          "id" => "player_002",
          "name" => "Jane Doe",
          "email" => "jane@example.com",
          "first_name" => "Jane",
          "last_name" => "Doe",
          "deleted" => false,
        },
      },
    ].freeze

    # Sample master roster member response
    MASTER_ROSTER_MEMBER = {
      "member" => {
        "id" => "player_001",
        "name" => "John Smith",
        "email" => "john@example.com",
        "first_name" => "John",
        "last_name" => "Smith",
        "deleted" => false,
      },
    }.freeze

    # Sample player events response
    PLAYER_EVENTS = {
      "member" => {
        "id" => "player_001",
        "name" => "John Smith",
        "email" => "john@example.com",
      },
      "events" => %w[event_001 event_002],
    }.freeze

    # Sample tee sheet response (API returns [ { "pairing_group" => {...} } ])
    TEE_SHEET = [
      {
        "pairing_group" => {
          "id" => "group_001",
          "hole" => 1,
          "tee_time" => " 8:30 AM ",
          "date" => "2026-04-15",
          "players" => [
            {
              "name" => "Wood, Tim",
              "position" => 0,
              "player_roster_id" => "player_001",
              "score_array" => [4, 4, 5, 3, 5, 4, 5, 5, 4, 4, 3, 4, 4, 5, 4, 3, 6, 4],
            },
            {
              "name" => "Erskine, William",
              "position" => 1,
              "player_roster_id" => "player_002",
              "score_array" => [7, 6, 6, 4, 5, 5, 5, 4, 5, 4, 3, 4, 6, 5, 5, 4, 6, 5],
            },
          ],
        },
      },
      {
        "pairing_group" => {
          "id" => "group_002",
          "hole" => 10,
          "tee_time" => "8:40 AM",
          "date" => "2026-04-15",
          "players" => [
            {
              "name" => "Player, Three",
              "position" => 0,
              "player_roster_id" => "player_003",
              "score_array" => [5, 5, 4, 4, 5, 3, 4, 5, 4, 5, 4, 4, 5, 5, 4, 3, 5, 4],
            },
          ],
        },
      },
    ].freeze

    TOURNAMENT_RESULTS = {
      "event" => {
        "title" => "Flight A - Gross",
        "players" => [
          {
            "position" => "1",
            "name" => "John Smith",
            "score" => "-4",
          },
          {
            "position" => "T2",
            "name" => "Jane Doe",
            "score" => "-3",
          },
        ],
      },
    }.freeze

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
