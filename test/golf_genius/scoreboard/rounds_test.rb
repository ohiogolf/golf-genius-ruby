# frozen_string_literal: true

require "test_helper"

class RoundsTest < Minitest::Test
  # Tests for Rounds collection class methods

  def test_size_returns_round_count
    rounds = create_rounds(3)

    assert_equal 3, rounds.size
  end

  def test_size_returns_zero_for_empty_rounds
    rounds = create_rounds(0)

    assert_equal 0, rounds.size
  end

  def test_current_returns_playing_round
    rounds = create_rounds_with_statuses([false, true, false])

    current = rounds.current

    assert_equal "R2", current.name
    assert_predicate current, :playing?
  end

  def test_current_returns_nil_when_no_round_playing
    rounds = create_rounds_with_statuses([false, false, false])

    assert_nil rounds.current
  end

  def test_current_returns_first_playing_round_when_multiple_playing
    # Edge case: multiple rounds marked as playing (shouldn't happen but test anyway)
    rounds = create_rounds_with_statuses([false, true, true])

    current = rounds.current

    assert_equal "R2", current.name
  end

  def test_each_iterates_over_rounds
    rounds = create_rounds(3)
    names = rounds.map(&:name)

    assert_equal %w[R1 R2 R3], names
  end

  def test_each_returns_enumerator_without_block
    rounds = create_rounds(3)

    enumerator = rounds.each

    assert_instance_of Enumerator, enumerator
    assert_equal %w[R1 R2 R3], enumerator.map(&:name)
  end

  def test_bracket_access_returns_round_at_index
    rounds = create_rounds(3)

    assert_equal "R1", rounds[0].name
    assert_equal "R2", rounds[1].name
    assert_equal "R3", rounds[2].name
  end

  def test_bracket_access_returns_nil_for_out_of_bounds
    rounds = create_rounds(3)

    assert_nil rounds[3]
    assert_nil rounds[10]
  end

  def test_bracket_access_supports_negative_indices
    rounds = create_rounds(3)

    assert_equal "R3", rounds[-1].name
    assert_equal "R2", rounds[-2].name
    assert_equal "R1", rounds[-3].name
  end

  def test_first_returns_first_round
    rounds = create_rounds(3)

    first = rounds.first

    assert_equal "R1", first.name
    assert_equal 101, first.id
  end

  def test_first_returns_nil_for_empty_rounds
    rounds = create_rounds(0)

    assert_nil rounds.first
  end

  def test_last_returns_last_round
    rounds = create_rounds(3)

    last = rounds.last

    assert_equal "R3", last.name
    assert_equal 103, last.id
  end

  def test_last_returns_nil_for_empty_rounds
    rounds = create_rounds(0)

    assert_nil rounds.last
  end

  def test_to_h_returns_array_of_hashes
    rounds = create_rounds(2)

    result = rounds.to_h

    assert_instance_of Array, result
    assert_equal 2, result.size
    assert_instance_of Hash, result.first
    assert_equal 101, result.first[:id]
    assert_equal "R1", result.first[:name]
  end

  def test_to_h_returns_empty_array_for_no_rounds
    rounds = create_rounds(0)

    assert_empty rounds.to_h
  end

  def test_enumerable_methods_work
    rounds = create_rounds(4)

    # Test that Enumerable methods are available
    assert_equal 4, rounds.count
    assert rounds.any?(&:playing?)
    assert_equal "R2", rounds.find(&:playing?).name
    assert_equal %w[R1 R2 R3 R4], rounds.map(&:name)
  end

  def test_select_returns_array_not_rounds
    rounds = create_rounds(3)

    playing = rounds.select(&:playing?)

    # Enumerable methods return arrays, not Rounds instances
    assert_instance_of Array, playing
    assert_equal 1, playing.size
    assert_equal "R2", playing.first.name
  end

  def test_rounds_are_in_order
    # Rounds should maintain the order they were created in
    rounds_data = [
      { id: 103, name: "R3", date: "2026-03-17", in_progress: false },
      { id: 101, name: "R1", date: "2026-03-15", in_progress: false },
      { id: 102, name: "R2", date: "2026-03-16", in_progress: false },
    ]

    rounds = GolfGenius::Scoreboard::Rounds.new(rounds_data)

    assert_equal %w[R3 R1 R2], rounds.map(&:name)
  end

  private

  def create_rounds(count)
    rounds_data = count.times.map do |i|
      {
        id: 101 + i,
        name: "R#{i + 1}",
        date: "2026-03-#{15 + i}",
        in_progress: i == 1, # R2 is playing
      }
    end

    GolfGenius::Scoreboard::Rounds.new(rounds_data)
  end

  def create_rounds_with_statuses(in_progress_flags)
    rounds_data = in_progress_flags.each_with_index.map do |in_progress, i|
      {
        id: 101 + i,
        name: "R#{i + 1}",
        date: "2026-03-#{15 + i}",
        in_progress: in_progress,
      }
    end

    GolfGenius::Scoreboard::Rounds.new(rounds_data)
  end
end
