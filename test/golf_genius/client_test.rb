# frozen_string_literal: true

require "test_helper"

class ClientTest < Minitest::Test
  def setup
    setup_test_configuration
  end

  def teardown
    GolfGenius.reset_configuration!
  end

  def test_client_initialization_with_api_key
    client = GolfGenius::Client.new(api_key: "custom_key")
    assert_equal "custom_key", client.api_key
  end

  def test_client_initialization_with_global_api_key
    client = GolfGenius::Client.new
    assert_equal TEST_API_KEY, client.api_key
  end

  def test_client_initialization_without_api_key_raises
    GolfGenius.api_key = nil

    assert_raises(GolfGenius::ConfigurationError) do
      GolfGenius::Client.new
    end
  end

  def test_client_seasons_list
    stub_list("/seasons", SEASONS)

    client = GolfGenius::Client.new
    seasons = client.seasons.list

    assert_equal 2, seasons.length
    assert_kind_of GolfGenius::Season, seasons.first
  end

  def test_client_seasons_fetch
    stub_fetch("/seasons", "season_001", SEASON)

    client = GolfGenius::Client.new
    season = client.seasons.fetch("season_001")

    assert_kind_of GolfGenius::Season, season
    assert_equal "season_001", season.id
  end

  def test_client_categories_list
    stub_list("/categories", CATEGORIES)

    client = GolfGenius::Client.new
    categories = client.categories.list

    assert_equal 2, categories.length
    assert_kind_of GolfGenius::Category, categories.first
  end

  def test_client_directories_list
    stub_list("/directories", DIRECTORIES)

    client = GolfGenius::Client.new
    directories = client.directories.list

    assert_equal 2, directories.length
    assert_kind_of GolfGenius::Directory, directories.first
  end

  def test_client_events_list
    stub_list("/events", EVENTS)

    client = GolfGenius::Client.new
    events = client.events.list

    assert_equal 2, events.length
    assert_kind_of GolfGenius::Event, events.first
  end

  def test_client_events_fetch
    stub_fetch("/events", "event_001", EVENT)

    client = GolfGenius::Client.new
    event = client.events.fetch("event_001")

    assert_kind_of GolfGenius::Event, event
    assert_equal "event_001", event.id
  end

  def test_client_events_roster
    stub_nested("/events/event_001/roster", EVENT_ROSTER)

    client = GolfGenius::Client.new
    roster = client.events.roster("event_001")

    assert_equal 3, roster.length
    assert_equal "John Smith", roster.first.name
  end

  def test_client_events_rounds
    stub_nested("/events/event_001/rounds", EVENT_ROUNDS)

    client = GolfGenius::Client.new
    rounds = client.events.rounds("event_001")

    assert_equal 2, rounds.length
  end

  def test_client_events_courses
    stub_nested("/events/event_001/courses", EVENT_COURSES)

    client = GolfGenius::Client.new
    courses = client.events.courses("event_001")

    assert_equal 2, courses.length
  end

  def test_client_events_tournaments
    stub_nested("/events/event_001/rounds/round_001/tournaments", TOURNAMENTS)

    client = GolfGenius::Client.new
    tournaments = client.events.tournaments("event_001", "round_001")

    assert_equal 2, tournaments.length
  end

  def test_client_auto_paging_each
    stub_api_request(
      method: :get,
      path: "/events",
      response_body: EVENTS,
      query: { page: "1" }
    )

    client = GolfGenius::Client.new
    collected = []

    client.events.auto_paging_each(page: 1) do |event|
      collected << event
    end

    assert_equal 2, collected.length
  end

  def test_client_list_all
    stub_api_request(
      method: :get,
      path: "/events",
      response_body: EVENTS,
      query: { page: "1" }
    )

    client = GolfGenius::Client.new
    all_events = client.events.list_all(page: 1)

    assert_equal 2, all_events.length
  end

  def test_client_with_custom_api_key
    custom_key = "custom_key_xyz"
    url = "#{TEST_BASE_URL}/api_v2/#{custom_key}/seasons"

    stub_request(:get, url).to_return(
      status: 200,
      body: SEASONS.to_json,
      headers: { "Content-Type" => "application/json" }
    )

    client = GolfGenius::Client.new(api_key: custom_key)
    seasons = client.seasons.list

    assert_equal 2, seasons.length
  end

  def test_resource_proxy_roster_only_for_events
    client = GolfGenius::Client.new

    assert_raises(NoMethodError) do
      client.seasons.roster("some_id")
    end
  end

  def test_multiple_clients_with_different_keys
    key1 = "key_for_org_1"
    key2 = "key_for_org_2"

    stub_request(:get, "#{TEST_BASE_URL}/api_v2/#{key1}/seasons").to_return(
      status: 200,
      body: [{ "id" => "s1", "name" => "Org 1 Season" }].to_json,
      headers: { "Content-Type" => "application/json" }
    )

    stub_request(:get, "#{TEST_BASE_URL}/api_v2/#{key2}/seasons").to_return(
      status: 200,
      body: [{ "id" => "s2", "name" => "Org 2 Season" }].to_json,
      headers: { "Content-Type" => "application/json" }
    )

    client1 = GolfGenius::Client.new(api_key: key1)
    client2 = GolfGenius::Client.new(api_key: key2)

    seasons1 = client1.seasons.list
    seasons2 = client2.seasons.list

    assert_equal "Org 1 Season", seasons1.first.name
    assert_equal "Org 2 Season", seasons2.first.name
  end
end
