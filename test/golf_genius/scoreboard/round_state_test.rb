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

  private

  def create_round(date:, in_progress:)
    GolfGenius::Scoreboard::Round.new(
      id: 123,
      name: "Round 1",
      date: date,
      in_progress: in_progress
    )
  end
end
