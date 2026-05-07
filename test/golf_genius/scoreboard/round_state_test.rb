# frozen_string_literal: true

require "test_helper"

class RoundStateTest < Minitest::Test
  def test_complete_returns_false_for_future_rounds
    round = create_round(date: Date.today + 1, in_progress: false)

    refute_predicate round, :complete?
    assert_predicate round, :future?
  end

  def test_complete_returns_true_for_past_rounds_that_are_not_in_progress
    round = create_round(date: Date.today - 1, in_progress: false)

    assert_predicate round, :complete?
    refute_predicate round, :future?
  end

  def test_complete_returns_false_for_rounds_in_progress
    round = create_round(date: Date.today, in_progress: true)

    refute_predicate round, :complete?
    refute_predicate round, :future?
    assert_predicate round, :playing?
  end

  def test_complete_returns_false_for_same_day_round_without_explicit_status
    round = create_round(date: Date.today, in_progress: false)

    refute_predicate round, :complete?
    refute_predicate round, :future?
  end

  def test_complete_uses_explicit_completed_status
    round = create_round(date: Date.today, in_progress: false, status: "completed")

    assert_predicate round, :complete?
  end

  def test_unstarted_uses_explicit_not_started_status
    round = create_round(date: Date.today, in_progress: false, status: "not started")

    assert_predicate round, :unstarted?
    refute_predicate round, :complete?
  end

  def test_complete_handles_string_keyed_same_day_round_data
    round = GolfGenius::Scoreboard::Round.new(
      "id" => 123,
      "name" => "Round 1",
      "date" => Date.today.to_s,
      "in_progress" => false
    )

    refute_predicate round, :complete?
  end

  def test_explicit_status_uses_string_keys
    round = GolfGenius::Scoreboard::Round.new(
      "id" => 123,
      "name" => "Round 1",
      "date" => Date.today.to_s,
      "in_progress" => false,
      "status" => "completed"
    )

    assert_predicate round, :complete?
  end

  def test_playing_uses_string_keyed_in_progress_value
    round = GolfGenius::Scoreboard::Round.new(
      "id" => 123,
      "name" => "Round 1",
      "date" => Date.today.to_s,
      "in_progress" => true
    )

    assert_predicate round, :playing?
  end

  private

  def create_round(date:, in_progress:, status: nil)
    GolfGenius::Scoreboard::Round.new(
      id: 123,
      name: "Round 1",
      date: date,
      in_progress: in_progress,
      status: status
    )
  end
end
