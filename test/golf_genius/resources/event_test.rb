# frozen_string_literal: true

require "test_helper"

class EventTest < Minitest::Test
  def setup
    setup_test_configuration
  end

  def teardown
    GolfGenius.reset_configuration!
  end

  def test_list_events
    stub_api_request(method: :get, path: "/events", response_body: EVENTS, query: { "page" => "1" })
    stub_api_request(method: :get, path: "/events", response_body: [], query: { "page" => "2" })

    events = GolfGenius::Event.list

    assert_kind_of Array, events
    assert_equal 2, events.length
    assert_kind_of GolfGenius::Event, events.first
    assert_equal "event_001", events.first.id
    assert_equal "Spring Championship", events.first.name
  end

  def test_list_events_with_filters
    stub_api_request(
      method: :get,
      path: "/events",
      response_body: EVENTS,
      query: { "page" => "1", "season" => "season_001", "archived" => "false" }
    )

    events = GolfGenius::Event.list(page: 1, season_id: "season_001", archived: false)

    assert_kind_of Array, events
  end

  def test_list_events_accepts_resource_objects
    dir = GolfGenius::Directory.construct_from(GolfGenius::TestFixtures::DIRECTORY)
    stub_api_request(
      method: :get,
      path: "/events",
      response_body: EVENTS,
      query: { "directory" => "dir_001", "page" => "1" }
    )
    stub_api_request(
      method: :get,
      path: "/events",
      response_body: [],
      query: { "directory" => "dir_001", "page" => "2" }
    )

    events = GolfGenius::Event.list(directory: dir)

    assert_kind_of Array, events
    assert_equal 2, events.length
  end

  def test_fetch_event
    stub_fetch("/events", "event_001", EVENT)

    event = GolfGenius::Event.fetch("event_001")

    assert_kind_of GolfGenius::Event, event
    assert_equal "event_001", event.id
    assert_equal "Spring Championship", event.name
    assert_equal "tournament", event.type
  end

  def test_event_nested_season
    event = GolfGenius::Event.construct_from(EVENT)

    assert_kind_of GolfGenius::GolfGeniusObject, event.season
    assert_equal "season_001", event.season.id
    assert_equal "2026 Season", event.season.name
  end

  def test_event_nested_category
    event = GolfGenius::Event.construct_from(EVENT)

    assert_kind_of GolfGenius::GolfGeniusObject, event.category
    assert_equal "cat_001", event.category.id
    assert_equal "Member Events", event.category.name
    assert_equal "#FF5733", event.category.color
  end

  def test_event_roster
    stub_nested("/events/event_001/roster", EVENT_ROSTER)

    roster = GolfGenius::Event.roster("event_001")

    assert_kind_of Array, roster
    assert_equal 3, roster.length
    assert_kind_of GolfGenius::GolfGeniusObject, roster.first
    assert_equal "player_001", roster.first.id
    assert_equal "John Smith", roster.first.name
    assert_in_delta(12.5, roster.first.handicap)
  end

  def test_event_roster_with_params
    stub_api_request(
      method: :get,
      path: "/events/event_001/roster",
      response_body: EVENT_ROSTER,
      query: { photo: "true" }
    )

    roster = GolfGenius::Event.roster("event_001", photo: true)

    assert_equal 3, roster.length
  end

  def test_event_rounds
    stub_nested("/events/event_001/rounds", EVENT_ROUNDS)

    rounds = GolfGenius::Event.rounds("event_001")

    assert_kind_of Array, rounds
    assert_equal 2, rounds.length
    assert_kind_of GolfGenius::GolfGeniusObject, rounds.first
    assert_equal "round_001", rounds.first.id
    assert_equal 1, rounds.first.number
  end

  def test_event_courses
    stub_nested("/events/event_001/courses", EVENT_COURSES)

    courses = GolfGenius::Event.courses("event_001")

    assert_kind_of Array, courses
    assert_equal 2, courses.length
    assert_kind_of GolfGenius::GolfGeniusObject, courses.first
    assert_equal "course_001", courses.first.id
    assert_in_delta(74.5, courses.first.rating)
  end

  def test_event_tournaments
    stub_nested("/events/event_001/rounds/round_001/tournaments", TOURNAMENTS)

    tournaments = GolfGenius::Event.tournaments("event_001", "round_001")

    assert_kind_of Array, tournaments
    assert_equal 2, tournaments.length
    assert_kind_of GolfGenius::GolfGeniusObject, tournaments.first
    assert_equal "tourn_001", tournaments.first.id
    assert_equal "Flight A - Gross", tournaments.first.name
  end

  def test_auto_paging_each
    # Stub page 1 (full page of 25 items)
    stub_api_request(
      method: :get,
      path: "/events",
      response_body: EVENTS_PAGE_1,
      query: { "page" => "1", "per_page" => "25" }
    )

    # Stub page 2 (partial page of 5 items - indicates last page)
    stub_api_request(
      method: :get,
      path: "/events",
      response_body: EVENTS_PAGE_2,
      query: { "page" => "2", "per_page" => "25" }
    )

    collected = []
    GolfGenius::Event.auto_paging_each(page: 1, per_page: 25) do |event|
      collected << event
    end

    assert_equal 30, collected.length
    assert_equal "event_001", collected.first.id
    assert_equal "event_030", collected.last.id
  end

  def test_auto_paging_each_returns_enumerator
    stub_api_request(
      method: :get,
      path: "/events",
      response_body: EVENTS,
      query: { page: "1" }
    )

    enumerator = GolfGenius::Event.auto_paging_each(page: 1)

    assert_kind_of Enumerator, enumerator
  end

  def test_list_all
    stub_api_request(
      method: :get,
      path: "/events",
      response_body: EVENTS_PAGE_1,
      query: { "page" => "1", "per_page" => "25" }
    )

    stub_api_request(
      method: :get,
      path: "/events",
      response_body: EVENTS_PAGE_2,
      query: { "page" => "2", "per_page" => "25" }
    )

    all_events = GolfGenius::Event.list_all(page: 1, per_page: 25)

    assert_kind_of Array, all_events
    assert_equal 30, all_events.length
  end
end
