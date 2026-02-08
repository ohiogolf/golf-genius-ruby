# frozen_string_literal: true

require "test_helper"

class RoundNumberTest < Minitest::Test
  # Test extracting number from standard round names
  def test_number_extracts_from_r1_format
    round = create_round(name: "R1")

    assert_equal 1, round.number
  end

  def test_number_extracts_from_r2_format
    round = create_round(name: "R2")

    assert_equal 2, round.number
  end

  def test_number_extracts_from_r10_format
    round = create_round(name: "R10")

    assert_equal 10, round.number
  end

  # Test extracting number from descriptive names
  def test_number_extracts_from_round_1_format
    round = create_round(name: "Round 1")

    assert_equal 1, round.number
  end

  def test_number_extracts_from_round_3_format
    round = create_round(name: "Round 3")

    assert_equal 3, round.number
  end

  # Test extracting first number when multiple present
  def test_number_extracts_first_number_when_multiple
    round = create_round(name: "R2 Day 1")

    assert_equal 2, round.number
  end

  # Test edge cases
  def test_number_returns_nil_for_no_number
    round = create_round(name: "Final")

    assert_nil round.number
  end

  def test_number_returns_nil_for_nil_name
    round = create_round(name: nil)

    assert_nil round.number
  end

  def test_number_returns_nil_for_empty_name
    round = create_round(name: "")

    assert_nil round.number
  end

  # Test various name formats
  def test_number_extracts_from_lowercase_round
    round = create_round(name: "round 4")

    assert_equal 4, round.number
  end

  def test_number_extracts_from_hyphenated_format
    round = create_round(name: "Round-2")

    assert_equal 2, round.number
  end

  private

  def create_round(name:)
    data = {
      id: 123,
      name: name,
      date: "2026-03-15",
      in_progress: false,
    }

    GolfGenius::Scoreboard::Round.new(data)
  end
end
