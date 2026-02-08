# frozen_string_literal: true

require "test_helper"

class ColumnTypeTest < Minitest::Test
  # Test position column type
  def test_position_format_returns_position_type
    column = create_column(format: "position", label: "Pos")

    assert_equal :position, column.type
  end

  # Test player column type
  def test_player_format_returns_player_type
    column = create_column(format: "player", label: "Player")

    assert_equal :player, column.type
  end

  # Test thru column type
  def test_thru_format_returns_thru_type
    column = create_column(format: "thru", label: "Thru R2", round_id: 123)

    assert_equal :thru, column.type
  end

  # Test to-par column types
  def test_to_par_gross_format_returns_to_par_type
    column = create_column(format: "to-par-gross", label: "To Par R1", round_id: 123)

    assert_equal :to_par, column.type
  end

  def test_to_par_net_format_returns_to_par_type
    column = create_column(format: "to-par-net", label: "To Par Net R1", round_id: 123)

    assert_equal :to_par, column.type
  end

  def test_total_to_par_gross_format_returns_to_par_type
    column = create_column(format: "total-to-par-gross", label: "Total To Par Gross")

    assert_equal :to_par, column.type
  end

  def test_total_to_par_net_format_returns_to_par_type
    column = create_column(format: "total-to-par-net", label: "Total To Par Net")

    assert_equal :to_par, column.type
  end

  # Test strokes column types
  def test_round_total_format_returns_strokes_type
    column = create_column(format: "round-total", label: "R1", round_id: 123)

    assert_equal :strokes, column.type
  end

  def test_total_gross_format_returns_strokes_type
    column = create_column(format: "total-gross", label: "Total Gross")

    assert_equal :strokes, column.type
  end

  def test_total_net_format_returns_strokes_type
    column = create_column(format: "total-net", label: "Total Net")

    assert_equal :strokes, column.type
  end

  def test_total_format_returns_strokes_type
    column = create_column(format: "total", label: "Total")

    assert_equal :strokes, column.type
  end

  # Test unknown/other format
  def test_unknown_format_returns_other_type
    column = create_column(format: "unknown-format", label: "Unknown")

    assert_equal :other, column.type
  end

  # Test summary? predicate
  def test_summary_returns_true_when_no_round_id
    column = create_column(format: "position", label: "Pos", round_id: nil)

    assert_predicate column, :summary?
  end

  def test_summary_returns_false_when_round_id_present
    column = create_column(format: "round-total", label: "R1", round_id: 123)

    refute_predicate column, :summary?
  end

  # Test round? predicate
  def test_round_returns_true_when_round_id_present
    column = create_column(format: "round-total", label: "R1", round_id: 123)

    assert_predicate column, :round?
  end

  def test_round_returns_false_when_no_round_id
    column = create_column(format: "position", label: "Pos", round_id: nil)

    refute_predicate column, :round?
  end

  # Test cell delegation
  def test_cell_delegates_type_to_column
    column = create_column(format: "position", label: "Pos")
    cell = GolfGenius::Scoreboard::Cell.new("1", column)

    assert_equal :position, cell.type
  end

  def test_cell_delegates_summary_to_column
    column = create_column(format: "position", label: "Pos", round_id: nil)
    cell = GolfGenius::Scoreboard::Cell.new("1", column)

    assert_predicate cell, :summary?
  end

  def test_cell_delegates_round_to_column
    column = create_column(format: "round-total", label: "R1", round_id: 123)
    cell = GolfGenius::Scoreboard::Cell.new("72", column)

    assert_predicate cell, :round?
  end

  def test_cell_delegates_position_predicate_to_column
    column = create_column(format: "position", label: "Pos")
    cell = GolfGenius::Scoreboard::Cell.new("1", column)

    assert_predicate cell, :position?
    refute_predicate cell, :player?
  end

  def test_cell_delegates_player_predicate_to_column
    column = create_column(format: "player", label: "Player")
    cell = GolfGenius::Scoreboard::Cell.new("John Doe", column)

    assert_predicate cell, :player?
    refute_predicate cell, :position?
  end

  def test_cell_delegates_to_par_predicate_to_column
    column = create_column(format: "to-par-gross", label: "To Par")
    cell = GolfGenius::Scoreboard::Cell.new("-2", column)

    assert_predicate cell, :to_par?
    refute_predicate cell, :position?
  end

  def test_cell_delegates_strokes_predicate_to_column
    column = create_column(format: "round-total", label: "R1")
    cell = GolfGenius::Scoreboard::Cell.new("72", column)

    assert_predicate cell, :strokes?
    refute_predicate cell, :position?
  end

  def test_cell_delegates_thru_predicate_to_column
    column = create_column(format: "thru", label: "Thru")
    cell = GolfGenius::Scoreboard::Cell.new("F", column)

    assert_predicate cell, :thru?
    refute_predicate cell, :position?
  end

  # Test case insensitivity
  def test_type_is_case_insensitive_uppercase
    column = create_column(format: "POSITION", label: "Pos")

    assert_equal :position, column.type
  end

  def test_type_is_case_insensitive_mixed_case
    column = create_column(format: "To-Par-Gross", label: "To Par")

    assert_equal :to_par, column.type
  end

  def test_type_is_case_insensitive_player
    column = create_column(format: "PLAYER", label: "Player")

    assert_equal :player, column.type
  end

  # Test edge cases
  def test_type_returns_other_for_nil_format
    column = create_column(format: nil, label: "Unknown")

    assert_equal :other, column.type
  end

  def test_type_returns_other_for_empty_format
    column = create_column(format: "", label: "Unknown")

    assert_equal :other, column.type
  end

  def test_type_returns_other_for_unrecognized_format
    column = create_column(format: "stableford-points", label: "Points")

    assert_equal :other, column.type
  end

  def test_type_warns_for_unknown_format
    column = create_column(format: "unknown-format", label: "Unknown")

    # Capture warning
    _, err = capture_io do
      assert_equal :other, column.type
    end

    assert_match(/Unknown column format: "unknown-format"/, err)
  end

  def test_type_does_not_warn_for_empty_format
    column = create_column(format: "", label: "Unknown")

    # Capture output - should be no warning
    _, err = capture_io do
      assert_equal :other, column.type
    end

    assert_empty err
  end

  # Test type predicate methods
  def test_position_predicate
    column = create_column(format: "position", label: "Pos")

    assert_predicate column, :position?
    refute_predicate column, :player?
    refute_predicate column, :to_par?
    refute_predicate column, :strokes?
    refute_predicate column, :thru?
  end

  def test_player_predicate
    column = create_column(format: "player", label: "Player")

    assert_predicate column, :player?
    refute_predicate column, :position?
    refute_predicate column, :to_par?
    refute_predicate column, :strokes?
    refute_predicate column, :thru?
  end

  def test_to_par_predicate
    column = create_column(format: "to-par-gross", label: "To Par")

    assert_predicate column, :to_par?
    refute_predicate column, :position?
    refute_predicate column, :player?
    refute_predicate column, :strokes?
    refute_predicate column, :thru?
  end

  def test_strokes_predicate
    column = create_column(format: "round-total", label: "R1")

    assert_predicate column, :strokes?
    refute_predicate column, :position?
    refute_predicate column, :player?
    refute_predicate column, :to_par?
    refute_predicate column, :thru?
  end

  def test_thru_predicate
    column = create_column(format: "thru", label: "Thru")

    assert_predicate column, :thru?
    refute_predicate column, :position?
    refute_predicate column, :player?
    refute_predicate column, :to_par?
    refute_predicate column, :strokes?
  end

  def test_predicates_work_with_select
    columns = [
      create_column(format: "position", label: "Pos"),
      create_column(format: "player", label: "Player"),
      create_column(format: "to-par-gross", label: "To Par"),
      create_column(format: "round-total", label: "R1"),
      create_column(format: "thru", label: "Thru"),
    ]

    assert_equal 1, columns.select(&:position?).size
    assert_equal 1, columns.select(&:player?).size
    assert_equal 1, columns.select(&:to_par?).size
    assert_equal 1, columns.select(&:strokes?).size
    assert_equal 1, columns.select(&:thru?).size
  end

  private

  def create_column(format:, label:, round_id: nil)
    data = {
      key: :test,
      format: format,
      label: label,
      index: 0,
      round_id: round_id,
      round_name: round_id ? "R1" : nil,
    }

    GolfGenius::Scoreboard::Column.new(data)
  end
end
