# frozen_string_literal: true

require "test_helper"

class ResourceTest < Minitest::Test
  def test_nested_hash_conversion
    # Simulate an API response with nested objects
    data = {
      "id" => "event123",
      "name" => "Test Event",
      "season" => {
        "id" => "season456",
        "name" => "2026 Season"
      }
    }

    event = GolfGenius::Event.construct_from(data)

    # Top-level attributes should work
    assert_equal "event123", event.id
    assert_equal "Test Event", event.name

    # Nested objects should be converted to GolfGeniusObject
    assert_kind_of GolfGenius::GolfGeniusObject, event.season
    assert_equal "season456", event.season.id
    assert_equal "2026 Season", event.season.name
  end

  def test_nested_array_conversion
    # Simulate an API response with nested array of objects
    data = {
      "id" => "event123",
      "participants" => [
        {"id" => "p1", "name" => "Player 1"},
        {"id" => "p2", "name" => "Player 2"}
      ]
    }

    event = GolfGenius::Event.construct_from(data)

    # Array should remain an array
    assert_kind_of Array, event.participants
    assert_equal 2, event.participants.length

    # But elements should be GolfGeniusObjects
    assert_kind_of GolfGenius::GolfGeniusObject, event.participants.first
    assert_equal "p1", event.participants.first.id
    assert_equal "Player 1", event.participants.first.name
  end

  def test_deeply_nested_conversion
    # Test deeply nested structures
    data = {
      "id" => "event123",
      "rounds" => [
        {
          "id" => "round1",
          "tournaments" => [
            {"id" => "t1", "name" => "Tournament 1"},
            {"id" => "t2", "name" => "Tournament 2"}
          ]
        }
      ]
    }

    event = GolfGenius::Event.construct_from(data)

    # Deep nesting should all be converted
    round = event.rounds.first
    assert_kind_of GolfGenius::GolfGeniusObject, round
    assert_equal "round1", round.id

    tournament = round.tournaments.first
    assert_kind_of GolfGenius::GolfGeniusObject, tournament
    assert_equal "t1", tournament.id
    assert_equal "Tournament 1", tournament.name
  end

  def test_to_h_preserves_structure
    data = {
      "id" => "event123",
      "season" => {"id" => "season456", "name" => "2026 Season"}
    }

    event = GolfGenius::Event.construct_from(data)
    hash = event.to_h

    assert_kind_of Hash, hash
    assert_equal "event123", hash[:id]
    # Note: nested objects remain as GolfGeniusObjects in to_h
    assert_kind_of GolfGenius::GolfGeniusObject, hash[:season]
  end
end
