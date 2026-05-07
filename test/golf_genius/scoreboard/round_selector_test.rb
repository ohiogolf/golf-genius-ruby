# frozen_string_literal: true

require "test_helper"

class RoundSelectorTest < Minitest::Test
  def test_select_current_prefers_latest_playing_round
    rounds = [
      build_round(id: 1, index: 1, status: "completed"),
      build_round(id: 2, index: 2, status: "in progress"),
      build_round(id: 3, index: 3, status: "in progress"),
    ]

    selected = GolfGenius::Scoreboard::RoundSelector.select_current(rounds)

    assert_equal 3, selected.id
  end

  def test_select_current_falls_back_to_latest_completed_then_earliest_unstarted
    completed_rounds = [
      build_round(id: 1, index: 1, status: "completed"),
      build_round(id: 2, index: 2, status: "completed"),
    ]
    upcoming_rounds = [
      build_round(id: 4, index: 4, status: "not started"),
      build_round(id: 3, index: 3, status: "not started"),
    ]

    assert_equal 2, GolfGenius::Scoreboard::RoundSelector.select_current(completed_rounds).id
    assert_equal 3, GolfGenius::Scoreboard::RoundSelector.select_current(upcoming_rounds).id
  end

  def test_fallback_source_round_returns_latest_started_older_round
    rounds = [
      build_round(id: 1, index: 1, status: "completed"),
      build_round(id: 2, index: 2, status: "completed"),
      build_round(id: 3, index: 3, status: "not started"),
    ]

    fallback = GolfGenius::Scoreboard::RoundSelector.fallback_source_round(rounds, 3)

    assert_equal 2, fallback.id
  end

  def test_normalize_rounds_wraps_hashes_and_accepts_round_like_objects
    round_object = build_round(id: 2, index: 2, status: "completed")
    hash_round = { id: 1, name: "Round 1", index: 1, status: "completed", date: "2026-03-15" }

    normalized = GolfGenius::Scoreboard::RoundSelector.normalize_rounds([hash_round, round_object])

    assert_instance_of GolfGenius::Scoreboard::Round, normalized.first
    assert_same round_object, normalized.last
  end

  def test_normalize_rounds_rejects_non_round_like_objects
    error = assert_raises(ArgumentError) do
      GolfGenius::Scoreboard::RoundSelector.normalize_rounds([Object.new])
    end

    assert_match(/round must be a Hash, Scoreboard::Round, or round-like object/, error.message)
  end

  private

  def build_round(id:, index:, status:, date: "2026-03-15")
    GolfGenius::Scoreboard::Round.new(
      {
        id: id,
        name: "Round #{index}",
        index: index,
        status: status,
        date: date,
      }
    )
  end
end
