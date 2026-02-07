# frozen_string_literal: true

require "test_helper"

class ColumnDecomposerTest < Minitest::Test
  def test_decompose_splits_summary_and_round_columns
    columns = [
      { format: "position", label: "Pos.", round_name: nil },
      { format: "player", label: "Player", round_name: nil },
      { format: "thru", label: "Thru R2", round_name: "R2" },
      { format: "to-par-gross", label: "To Par Gross R2", round_name: "R2" },
    ]

    rounds = [
      { id: 2001, name: "R2", in_progress: true },
    ]

    decomposer = GolfGenius::Scoreboard::ColumnDecomposer.new(columns, rounds)
    result = decomposer.decompose

    assert_equal 2, result[:summary].length
    assert_equal 1, result[:rounds].length
    assert_equal 2, result[:rounds][0][:columns].length
  end

  def test_decompose_generates_column_keys
    columns = [
      { format: "position", label: "Pos.", round_name: nil },
      { format: "total-to-par-gross", label: "Total To Par Gross", round_name: nil },
    ]

    rounds = []

    decomposer = GolfGenius::Scoreboard::ColumnDecomposer.new(columns, rounds)
    result = decomposer.decompose

    assert_equal "position", result[:summary][0][:key]
    assert_equal "total_to_par_gross", result[:summary][1][:key]
  end

  def test_decompose_simplifies_round_column_keys
    columns = [
      { format: "round-total", label: "R1", round_name: "R1" },
      { format: "to-par-gross", label: "To Par R2", round_name: "R2" },
    ]

    rounds = [
      { id: 2000, name: "R1", in_progress: false },
      { id: 2001, name: "R2", in_progress: true },
    ]

    decomposer = GolfGenius::Scoreboard::ColumnDecomposer.new(columns, rounds)
    result = decomposer.decompose

    # "round-total" => "total" for round-scoped columns
    assert_equal "total", result[:rounds][0][:columns][0][:key]
    assert_equal "to_par_gross", result[:rounds][1][:columns][0][:key]
  end

  def test_decompose_identifies_rounds_from_label
    # Column without explicit round_name but label contains round name
    columns = [
      { format: "round-total", label: "R1", round_name: nil },
    ]

    rounds = [
      { id: 2000, name: "R1", in_progress: false },
    ]

    decomposer = GolfGenius::Scoreboard::ColumnDecomposer.new(columns, rounds)
    result = decomposer.decompose

    assert_equal 0, result[:summary].length
    assert_equal 1, result[:rounds][0][:columns].length
  end

  def test_decompose_preserves_column_metadata
    columns = [
      { format: "player", label: "Player Name", round_name: nil },
    ]

    rounds = []

    decomposer = GolfGenius::Scoreboard::ColumnDecomposer.new(columns, rounds)
    result = decomposer.decompose

    col = result[:summary][0]

    assert_equal "player", col[:key]
    assert_equal "player", col[:format]
    assert_equal "Player Name", col[:label]
    assert_equal 0, col[:index]
  end

  def test_decompose_organizes_rounds_structure
    columns = [
      { format: "round-total", label: "R1", round_name: "R1" },
      { format: "thru", label: "Thru R2", round_name: "R2" },
    ]

    rounds = [
      { id: 2001, name: "R2", in_progress: true },
      { id: 2000, name: "R1", in_progress: false },
    ]

    decomposer = GolfGenius::Scoreboard::ColumnDecomposer.new(columns, rounds)
    result = decomposer.decompose

    # Should preserve rounds order from JSON
    assert_equal 2, result[:rounds].length
    assert_equal 2001, result[:rounds][0][:id]
    assert_equal "R2", result[:rounds][0][:name]
    assert_equal true, result[:rounds][0][:in_progress]
    assert_equal 1, result[:rounds][0][:columns].length

    assert_equal 2000, result[:rounds][1][:id]
    assert_equal "R1", result[:rounds][1][:name]
    assert_equal false, result[:rounds][1][:in_progress]
    assert_equal 1, result[:rounds][1][:columns].length
  end

  def test_decompose_handles_rounds_with_no_columns
    columns = [
      { format: "position", label: "Pos.", round_name: nil },
    ]

    rounds = [
      { id: 2000, name: "R1", in_progress: false },
    ]

    decomposer = GolfGenius::Scoreboard::ColumnDecomposer.new(columns, rounds)
    result = decomposer.decompose

    # R1 has no columns in HTML
    assert_empty result[:rounds][0][:columns]
  end
end
