# frozen_string_literal: true

require "test_helper"

class ParRelativeTest < Minitest::Test
  # Tests for par-relative helpers across Scorecard, Cell, and Row

  # --- Scorecard#total_to_par ---

  def test_scorecard_total_to_par_sums_values
    scorecard = GolfGenius::Scoreboard::Scorecard.new(
      to_par_gross: [-1, 0, 1, -1, 0, 0, -1, 0, 0, -1, 0, 1, -1, 0, 0, -1, 0, 0]
    )

    assert_equal(-4, scorecard.total_to_par)
  end

  def test_scorecard_total_to_par_skips_nil_holes
    # In-progress round: only 9 holes played
    scorecard = GolfGenius::Scoreboard::Scorecard.new(
      to_par_gross: [-1, 0, 1, -1, 0, 0, -1, 0, 0, nil, nil, nil, nil, nil, nil, nil, nil, nil]
    )

    assert_equal(-2, scorecard.total_to_par)
  end

  def test_scorecard_total_to_par_returns_nil_when_empty
    scorecard = GolfGenius::Scoreboard::Scorecard.new(
      to_par_gross: []
    )

    assert_nil scorecard.total_to_par
  end

  def test_scorecard_total_to_par_returns_nil_when_all_nil
    scorecard = GolfGenius::Scoreboard::Scorecard.new(
      to_par_gross: [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]
    )

    assert_nil scorecard.total_to_par
  end

  def test_scorecard_total_to_par_returns_zero_for_even_par
    scorecard = GolfGenius::Scoreboard::Scorecard.new(
      to_par_gross: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    )

    assert_equal 0, scorecard.total_to_par
  end

  # --- Cell par-relative helpers ---

  def test_cell_under_par
    cell = create_cell(value: "68", to_par: -4)

    assert_predicate cell, :under_par?
    refute_predicate cell, :over_par?
    refute_predicate cell, :even_par?
  end

  def test_cell_over_par
    cell = create_cell(value: "82", to_par: 10)

    refute_predicate cell, :under_par?
    assert_predicate cell, :over_par?
    refute_predicate cell, :even_par?
  end

  def test_cell_even_par
    cell = create_cell(value: "72", to_par: 0)

    refute_predicate cell, :under_par?
    refute_predicate cell, :over_par?
    assert_predicate cell, :even_par?
  end

  def test_cell_nil_to_par_returns_false_for_all
    cell = create_cell(value: "Player Name", to_par: nil)

    refute_predicate cell, :under_par?
    refute_predicate cell, :over_par?
    refute_predicate cell, :even_par?
  end

  def test_cell_backwards_compatible_without_to_par
    column = GolfGenius::Scoreboard::Column.new(
      key: :player, format: "player", label: "Player", index: 0
    )
    cell = GolfGenius::Scoreboard::Cell.new("John Doe", column)

    assert_nil cell.to_par
    refute_predicate cell, :under_par?
  end

  # --- Row#cells integration: to-par columns ---

  def test_to_par_column_cell_parses_negative_value
    tournament = create_par_tournament
    row = tournament.rows.first
    cell = row.cells.find { |c| c.column.format == "total-to-par-gross" }

    assert_equal(-4, cell.to_par)
    assert_predicate cell, :under_par?
  end

  def test_to_par_column_cell_parses_even
    tournament = create_par_tournament(summary_to_par: "E")
    row = tournament.rows.first
    cell = row.cells.find { |c| c.column.format == "total-to-par-gross" }

    assert_equal 0, cell.to_par
    assert_predicate cell, :even_par?
  end

  def test_to_par_column_cell_parses_positive_value
    tournament = create_par_tournament(summary_to_par: "+10")
    row = tournament.rows.first
    cell = row.cells.find { |c| c.column.format == "total-to-par-gross" }

    assert_equal 10, cell.to_par
    assert_predicate cell, :over_par?
  end

  def test_to_par_column_cell_nil_for_empty_value
    tournament = create_par_tournament(summary_to_par: nil)
    row = tournament.rows.first
    cell = row.cells.find { |c| c.column.format == "total-to-par-gross" }

    assert_nil cell.to_par
  end

  def test_to_par_column_cell_nil_for_non_numeric_string
    # Non-numeric strings like "WD" should be rescued to nil, not raise
    tournament = create_par_tournament(summary_to_par: "WD")
    row = tournament.rows.first
    cell = row.cells.find { |c| c.column.format == "total-to-par-gross" }

    assert_nil cell.to_par
  end

  # --- Row#cells integration: round strokes columns ---

  def test_round_strokes_cell_gets_to_par_from_scorecard
    tournament = create_par_tournament
    row = tournament.rows.first
    r1_cell = row.cells.find { |c| c.column.round_name == "R1" && c.column.strokes? }

    # R1 scorecard has to_par_gross summing to -2
    assert_equal(-2, r1_cell.to_par)
    assert_predicate r1_cell, :under_par?
  end

  def test_round_strokes_cell_nil_to_par_for_unplayed_round
    tournament = create_par_tournament
    row = tournament.rows.first
    r3_cell = row.cells.find { |c| c.column.round_name == "R3" && c.column.strokes? }

    # R3 not started — no to_par data
    assert_nil r3_cell.to_par
  end

  # --- Row#cells integration: summary strokes column ---

  def test_summary_strokes_cell_sums_to_par_across_rounds
    tournament = create_par_tournament
    row = tournament.rows.first
    total_cell = row.cells.find { |c| c.column.format == "total-gross" }

    # R1 to_par = -2, R2 to_par = -2, R3 = nil (unplayed) → total = -4
    assert_equal(-4, total_cell.to_par)
    assert_predicate total_cell, :under_par?
  end

  # --- Row#cells integration: non-score columns ---

  def test_position_cell_has_nil_to_par
    tournament = create_par_tournament
    row = tournament.rows.first
    pos_cell = row.cells.find { |c| c.column.position? }

    assert_nil pos_cell.to_par
  end

  def test_player_cell_has_nil_to_par
    tournament = create_par_tournament
    row = tournament.rows.first
    player_cell = row.cells.find { |c| c.column.player? }

    assert_nil player_cell.to_par
  end

  private

  def create_cell(value:, to_par:)
    column = GolfGenius::Scoreboard::Column.new(
      key: :total, format: "round-total", label: "R1", index: 0
    )
    GolfGenius::Scoreboard::Cell.new(value, column, to_par: to_par)
  end

  def create_par_tournament(summary_to_par: "-4")
    # 3-round tournament. Player completed R1 and R2, not started R3.
    r1_to_par = [-1, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] # sum = -2
    r2_to_par = [0, 0, -1, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] # sum = -2

    tournament_data = {
      meta: {
        tournament_id: 1,
        name: "Test Tournament",
        cut_text: nil,
        adjusted: false,
        rounds: [
          { id: 101, name: "R1", date: "2026-03-15", in_progress: false },
          { id: 102, name: "R2", date: "2026-03-16", in_progress: false },
          { id: 103, name: "R3", date: "2026-03-17", in_progress: true },
        ],
      },
      columns: {
        summary: [
          { key: :position, format: "position", label: "Pos", index: 0 },
          { key: :player, format: "player", label: "Player", index: 1 },
          { key: :total_to_par_gross, format: "total-to-par-gross", label: "To Par", index: 2 },
          { key: :total_gross, format: "total-gross", label: "Total", index: 3 },
        ],
        rounds: [
          {
            round_id: 101,
            round_name: "R1",
            columns: [
              { key: :total, format: "round-total", label: "R1", index: 4, round_id: 101, round_name: "R1" },
            ],
          },
          {
            round_id: 102,
            round_name: "R2",
            columns: [
              { key: :total, format: "round-total", label: "R2", index: 5, round_id: 102, round_name: "R2" },
            ],
          },
          {
            round_id: 103,
            round_name: "R3",
            columns: [
              { key: :total, format: "round-total", label: "R3", index: 6, round_id: 103, round_name: "R3" },
            ],
          },
        ],
      },
      rows: [
        {
          id: 1,
          name: "Test Player",
          player_ids: ["123"],
          affiliation: "Test Club",
          tournament_id: 1,
          summary: {
            position: "3",
            player: "Test Player",
            total_to_par_gross: summary_to_par,
            total_gross: "140",
          },
          rounds: {
            101 => {
              thru: "F", score: "-2", total: "70", status: "completed",
              to_par_gross: r1_to_par,
              scorecard: { thru: "F", gross_scores: Array.new(18) { 4 } },
            },
            102 => {
              thru: "F", score: "-2", total: "70", status: "completed",
              to_par_gross: r2_to_par,
              scorecard: { thru: "F", gross_scores: Array.new(18) { 4 } },
            },
            103 => {
              thru: "", score: "", total: "", status: "no_holes",
              to_par_gross: [],
              scorecard: { thru: "", gross_scores: [] },
            },
          },
        },
      ],
    }

    GolfGenius::Scoreboard::Tournament.new(tournament_data)
  end
end
