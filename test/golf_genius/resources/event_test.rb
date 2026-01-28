# frozen_string_literal: true

require "test_helper"

class EventTest < Minitest::Test
  def setup
    configure_test_api_key
  end

  def test_list_events
    skip "Set GOLF_GENIUS_API_KEY environment variable to run integration tests" unless ENV["GOLF_GENIUS_API_KEY"]

    VCR.use_cassette("events_list") do
      events = GolfGenius::Event.list(page: 1)
      assert_kind_of Array, events
    end
  end

  def test_list_events_with_filters
    skip "Set GOLF_GENIUS_API_KEY environment variable to run integration tests" unless ENV["GOLF_GENIUS_API_KEY"]

    VCR.use_cassette("events_list_filtered") do
      events = GolfGenius::Event.list(
        page: 1,
        season_id: "test_season",
        archived: false
      )
      assert_kind_of Array, events
    end
  end

  def test_retrieve_event
    VCR.use_cassette("event_retrieve") do
      skip "Need real event ID for integration test"
    end
  end

  def test_event_roster
    VCR.use_cassette("event_roster") do
      skip "Need real event ID for integration test"
    end
  end

  def test_event_rounds
    VCR.use_cassette("event_rounds") do
      skip "Need real event ID for integration test"
    end
  end

  def test_event_courses
    VCR.use_cassette("event_courses") do
      skip "Need real event ID for integration test"
    end
  end

  def test_event_tournaments
    VCR.use_cassette("event_tournaments") do
      skip "Need real event ID for integration test"
    end
  end
end
