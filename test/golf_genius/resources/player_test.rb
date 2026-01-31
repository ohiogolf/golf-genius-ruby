# frozen_string_literal: true

require "test_helper"

class PlayerTest < Minitest::Test
  def setup
    setup_test_configuration
  end

  def teardown
    GolfGenius.reset_configuration!
  end

  def test_list_players
    stub_api_request(method: :get, path: "/master_roster", response_body: MASTER_ROSTER, query: { "page" => "1" })
    stub_api_request(method: :get, path: "/master_roster", response_body: [], query: { "page" => "2" })

    players = GolfGenius::Player.list

    assert_kind_of Array, players
    assert_equal 2, players.length
    assert_kind_of GolfGenius::Player, players.first
    assert_equal "player_001", players.first.id
    assert_equal "John Smith", players.first.name
    assert_kind_of GolfGenius::Handicap, players.first.handicap
    assert_equal "12.5", players.first.handicap.index
    assert_kind_of GolfGenius::Tee, players.first.tee
    assert_equal "Blue", players.first.tee.name
  end

  def test_fetch_player
    stub_api_request(method: :get, path: "/master_roster", response_body: MASTER_ROSTER, query: { "page" => "1" })

    player = GolfGenius::Player.fetch("player_001")

    assert_kind_of GolfGenius::Player, player
    assert_equal "player_001", player.id
  end

  def test_fetch_player_by_email
    stub_api_request(method: :get, path: "/master_roster_member/john%40example.com", response_body: MASTER_ROSTER_MEMBER)

    player = GolfGenius::Player.fetch_by_email("john@example.com")

    assert_kind_of GolfGenius::Player, player
    assert_equal "player_001", player.id
  end

  def test_player_events
    stub_api_request(method: :get, path: "/players/player_001", response_body: PLAYER_EVENTS)

    summary = GolfGenius::Player.events("player_001")

    assert_kind_of GolfGenius::GolfGeniusObject, summary
    assert_equal %w[event_001 event_002], summary.events
    assert_kind_of GolfGenius::Player, summary.member
    assert_equal "player_001", summary.member.id
  end

  def test_player_instance_events
    stub_api_request(method: :get, path: "/players/player_001", response_body: PLAYER_EVENTS)

    player = GolfGenius::Player.construct_from(MASTER_ROSTER.first["member"])
    summary = player.events

    assert_equal %w[event_001 event_002], summary.events
  end

  def test_player_instance_events_requires_id
    player = GolfGenius::Player.construct_from({ "name" => "No ID" })

    error = assert_raises(ArgumentError) { player.events }
    assert_match(/no id/i, error.message)
  end
end
