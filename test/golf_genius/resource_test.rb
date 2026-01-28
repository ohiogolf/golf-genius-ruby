# frozen_string_literal: true

require "test_helper"

class ResourceTest < Minitest::Test
  def setup
    setup_test_configuration
  end

  def teardown
    GolfGenius.reset_configuration!
  end

  def test_resource_path_raises_without_constant
    # Create a test resource without RESOURCE_PATH
    klass = Class.new(GolfGenius::Resource)

    assert_raises(NotImplementedError) do
      klass.resource_path
    end
  end

  def test_resource_path_returns_constant
    assert_equal "/seasons", GolfGenius::Season.resource_path
    assert_equal "/categories", GolfGenius::Category.resource_path
    assert_equal "/directories", GolfGenius::Directory.resource_path
    assert_equal "/events", GolfGenius::Event.resource_path
  end

  def test_nested_hash_conversion
    data = {
      "id" => "event123",
      "name" => "Test Event",
      "season" => {
        "id" => "season456",
        "name" => "2026 Season"
      }
    }

    event = GolfGenius::Event.construct_from(data)

    assert_equal "event123", event.id
    assert_equal "Test Event", event.name
    assert_kind_of GolfGenius::GolfGeniusObject, event.season
    assert_equal "season456", event.season.id
    assert_equal "2026 Season", event.season.name
  end

  def test_nested_array_conversion
    data = {
      "id" => "event123",
      "participants" => [
        { "id" => "p1", "name" => "Player 1" },
        { "id" => "p2", "name" => "Player 2" }
      ]
    }

    event = GolfGenius::Event.construct_from(data)

    assert_kind_of Array, event.participants
    assert_equal 2, event.participants.length
    assert_kind_of GolfGenius::GolfGeniusObject, event.participants.first
    assert_equal "p1", event.participants.first.id
    assert_equal "Player 1", event.participants.first.name
  end

  def test_deeply_nested_conversion
    data = {
      "id" => "event123",
      "rounds" => [
        {
          "id" => "round1",
          "tournaments" => [
            { "id" => "t1", "name" => "Tournament 1" },
            { "id" => "t2", "name" => "Tournament 2" }
          ]
        }
      ]
    }

    event = GolfGenius::Event.construct_from(data)

    round = event.rounds.first
    assert_kind_of GolfGenius::GolfGeniusObject, round
    assert_equal "round1", round.id

    tournament = round.tournaments.first
    assert_kind_of GolfGenius::GolfGeniusObject, tournament
    assert_equal "t1", tournament.id
    assert_equal "Tournament 1", tournament.name
  end

  def test_to_h_recursively_serializes
    data = {
      "id" => "event123",
      "season" => { "id" => "season456", "name" => "2026 Season" },
      "participants" => [
        { "id" => "p1", "name" => "Player 1" }
      ]
    }

    event = GolfGenius::Event.construct_from(data)
    hash = event.to_h

    assert_kind_of Hash, hash
    assert_equal "event123", hash[:id]

    # Nested objects should now be plain hashes
    assert_kind_of Hash, hash[:season]
    assert_equal "season456", hash[:season][:id]

    # Nested arrays should contain plain hashes
    assert_kind_of Array, hash[:participants]
    assert_kind_of Hash, hash[:participants].first
    assert_equal "p1", hash[:participants].first[:id]
  end

  def test_to_json
    data = { "id" => "123", "name" => "Test" }
    obj = GolfGenius::GolfGeniusObject.construct_from(data)

    json = obj.to_json
    parsed = JSON.parse(json)

    assert_equal "123", parsed["id"]
    assert_equal "Test", parsed["name"]
  end

  def test_key_method
    obj = GolfGenius::GolfGeniusObject.construct_from({ "id" => "123", "name" => "Test" })

    assert obj.key?(:id)
    assert obj.key?("id")
    assert obj.key?(:name)
    refute obj.key?(:nonexistent)
  end

  def test_bracket_accessor
    obj = GolfGenius::GolfGeniusObject.construct_from({ "id" => "123", "name" => "Test" })

    assert_equal "123", obj[:id]
    assert_equal "Test", obj[:name]
    assert_nil obj[:nonexistent]
  end

  def test_refresh_uses_stored_api_key
    stub_fetch("/seasons", "season_001", SEASON)

    season = GolfGenius::Season.construct_from(SEASON, api_key: TEST_API_KEY)

    stub_fetch("/seasons", "season_001", SEASON.merge("name" => "Updated Name"))

    season.refresh

    assert_equal "Updated Name", season.name
  end
end
