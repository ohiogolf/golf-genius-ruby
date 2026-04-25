# frozen_string_literal: true

require "test_helper"

class ColumnTest < Minitest::Test
  def test_details_is_treated_as_known_other_format
    column = GolfGenius::Scoreboard::Column.new(
      key: :details,
      format: "details",
      label: "Details"
    )

    _stdout, stderr = capture_io do
      assert_equal :other, column.type
      refute column.position?
      refute column.player?
      refute column.to_par?
      refute column.strokes?
      refute column.thru?
    end

    assert_equal "", stderr
  end

  def test_unknown_formats_warn_once_even_when_type_is_reused
    column = GolfGenius::Scoreboard::Column.new(
      key: :mystery,
      format: "mystery-format",
      label: "Mystery"
    )

    _stdout, stderr = capture_io do
      assert_equal :other, column.type
      assert_equal :other, column.type
      refute column.position?
      refute column.player?
      refute column.to_par?
      refute column.strokes?
      refute column.thru?
    end

    assert_equal 1, stderr.lines.count
    assert_match(/Unknown column format: "mystery-format"/, stderr)
  end
end
