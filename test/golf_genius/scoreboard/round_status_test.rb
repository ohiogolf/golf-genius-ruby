# frozen_string_literal: true

require "test_helper"

class RoundStatusTest < Minitest::Test
  # Tests for Scorecard and Row round status methods
  # - Scorecard: playing?, finished?, not_started?
  # - Row: playing?, finished?, not_started? (for active round)
  # - Unplayed rounds return nil (not cumulative totals or status text)

  def test_scorecard_playing_returns_true_when_thru_is_numeric
    scorecard = create_scorecard(thru: "8", status: "partial")

    assert_predicate scorecard, :playing?
  end

  def test_scorecard_playing_returns_false_when_finished
    scorecard = create_scorecard(thru: "F", status: "completed")

    refute_predicate scorecard, :playing?
  end

  def test_scorecard_playing_returns_false_when_not_started
    scorecard = create_scorecard(thru: "", status: "no_holes")

    refute_predicate scorecard, :playing?
  end

  def test_scorecard_playing_returns_false_for_wd_with_numeric_thru_and_completed_status
    # WD player who played 6 holes: has numeric thru from partial play,
    # but status is "completed" because the round is over for them.
    scorecard = create_scorecard(thru: "6", status: "completed")

    refute_predicate scorecard, :playing?
  end

  def test_scorecard_finished_returns_true_when_thru_is_f
    scorecard = create_scorecard(thru: "F", status: "completed")

    assert_predicate scorecard, :finished?
  end

  def test_scorecard_finished_returns_true_when_status_completed
    scorecard = create_scorecard(thru: "18", status: "completed")

    assert_predicate scorecard, :finished?
  end

  def test_scorecard_finished_returns_false_when_playing
    scorecard = create_scorecard(thru: "8", status: "partial")

    refute_predicate scorecard, :finished?
  end

  def test_scorecard_not_started_returns_true_when_thru_empty
    scorecard = create_scorecard(thru: "", status: "no_holes")

    assert_predicate scorecard, :not_started?
  end

  def test_scorecard_not_started_returns_true_when_status_no_holes
    scorecard = create_scorecard(thru: nil, status: "no_holes")

    assert_predicate scorecard, :not_started?
  end

  def test_scorecard_not_started_returns_false_when_playing
    scorecard = create_scorecard(thru: "8", status: "partial")

    refute_predicate scorecard, :not_started?
  end

  def test_scorecard_not_started_returns_false_for_historical_round_with_score_data
    # Historical rounds have score data (total) but no thru/status metadata.
    # not_started? should return false since the player completed the round.
    scorecard = GolfGenius::Scoreboard::Scorecard.new(
      thru: nil, status: nil, total: "113"
    )

    refute_predicate scorecard, :not_started?
  end

  def test_scorecard_finished_returns_true_for_historical_round_with_score_data
    # Historical rounds with scores but no metadata should be considered finished.
    scorecard = GolfGenius::Scoreboard::Scorecard.new(
      thru: nil, status: nil, total: "113"
    )

    assert_predicate scorecard, :finished?
  end

  def test_scorecard_not_started_returns_true_when_total_is_empty
    # A truly unplayed round: no thru, no status, no total score.
    scorecard = GolfGenius::Scoreboard::Scorecard.new(
      thru: nil, status: nil, total: nil
    )

    assert_predicate scorecard, :not_started?
  end

  def test_scorecard_not_started_returns_true_when_total_is_nil
    # A round with no data (dashes are normalized to nil by RowDecomposer).
    scorecard = GolfGenius::Scoreboard::Scorecard.new(
      thru: "", status: nil, total: nil
    )

    assert_predicate scorecard, :not_started?
  end

  def test_unplayed_round_returns_nil_for_cut_player
    # Cut player: played R1 and R2, cut after R2, R3/R4 should be nil
    tournament = create_tournament_with_cut_player

    row = tournament.rows.first
    cells = row.cells

    # R1 cell should have value (played)
    r1_cell = cells.find { |c| c.column.round_name == "R1" }

    assert_equal "88", r1_cell.value

    # R2 cell should have value (played)
    r2_cell = cells.find { |c| c.column.round_name == "R2" }

    assert_equal "74", r2_cell.value

    # R3 cell should be nil (not played - cut)
    r3_cell = cells.find { |c| c.column.round_name == "R3" }

    assert_nil r3_cell.value

    # R4 cell should be nil (not played - cut)
    r4_cell = cells.find { |c| c.column.round_name == "R4" }

    assert_nil r4_cell.value
  end

  def test_unplayed_round_shows_nil_for_wd_player
    # WD player: played R1, withdrew before R2 (never started R2/R3).
    # Only the round where they were on the course shows "WD".
    # Rounds they never played show nil (dash).
    tournament = create_tournament_with_wd_player

    row = tournament.rows.first
    cells = row.cells

    # R1 cell should have value (played)
    r1_cell = cells.find { |c| c.column.round_name == "R1" }

    assert_equal "68", r1_cell.value

    # R2 cell should be nil (never started)
    r2_cell = cells.find { |c| c.column.round_name == "R2" }

    assert_nil r2_cell.value

    # R3 cell should be nil (never played)
    r3_cell = cells.find { |c| c.column.round_name == "R3" }

    assert_nil r3_cell.value
  end

  def test_historical_rounds_return_data_despite_missing_metadata
    # Regression test: Historical rounds may have score data but empty thru/status fields.
    # This can happen when rounds are complete but metadata wasn't fully populated.
    # We should return the data, not nil.
    tournament = create_tournament_with_historical_rounds_missing_metadata

    row = tournament.rows.first
    cells = row.cells

    # R1 should have value despite empty thru and status
    r1_cell = cells.find { |c| c.column.round_name == "R1" }

    assert_equal "72", r1_cell.value

    # R2 should have value despite empty thru and status
    r2_cell = cells.find { |c| c.column.round_name == "R2" }

    assert_equal "68", r2_cell.value

    # R3 (current round in progress) should have value
    r3_cell = cells.find { |c| c.column.round_name == "R3" }

    assert_equal "36", r3_cell.value
  end

  def test_row_playing_returns_true_when_player_on_course
    tournament = create_tournament_with_playing_player

    row = tournament.rows.first

    assert_predicate row, :playing?
  end

  def test_row_finished_returns_true_when_player_finished_active_round
    tournament = create_tournament_with_finished_player

    row = tournament.rows.first

    assert_predicate row, :finished?
  end

  def test_row_not_started_returns_true_when_player_hasnt_teed_off
    tournament = create_tournament_with_not_started_player

    row = tournament.rows.first

    assert_predicate row, :not_started?
  end

  def test_row_playing_returns_false_when_no_active_round
    tournament = create_tournament_with_no_active_round

    row = tournament.rows.first

    refute_predicate row, :playing?
  end

  private

  def create_scorecard(thru:, status:)
    data = {
      thru: thru,
      status: status,
      score: "72",
      gross_scores: [],
      net_scores: [],
      to_par_gross: [],
      to_par_net: [],
      totals: {},
    }
    GolfGenius::Scoreboard::Scorecard.new(data)
  end

  def create_tournament_with_cut_player
    tournament_data = {
      meta: {
        tournament_id: 1,
        name: "Test Tournament",
        cut_text: nil,
        adjusted: false,
        rounds: [
          { id: 101, name: "R1", date: "2026-03-15", in_progress: false },
          { id: 102, name: "R2", date: "2026-03-16", in_progress: false },
          { id: 103, name: "R3", date: "2026-03-17", in_progress: false },
          { id: 104, name: "R4", date: "2026-03-18", in_progress: false },
        ],
      },
      columns: {
        summary: [
          { key: :position, format: "position", label: "Pos", index: 0 },
          { key: :player, format: "player", label: "Player", index: 1 },
        ],
        rounds: [
          {
            round_id: 101,
            round_name: "R1",
            columns: [
              { key: :total, format: "round-total", label: "R1", index: 2, round_id: 101, round_name: "R1" },
            ],
          },
          {
            round_id: 102,
            round_name: "R2",
            columns: [
              { key: :total, format: "round-total", label: "R2", index: 3, round_id: 102, round_name: "R2" },
            ],
          },
          {
            round_id: 103,
            round_name: "R3",
            columns: [
              { key: :total, format: "round-total", label: "R3", index: 4, round_id: 103, round_name: "R3" },
            ],
          },
          {
            round_id: 104,
            round_name: "R4",
            columns: [
              { key: :total, format: "round-total", label: "R4", index: 5, round_id: 104, round_name: "R4" },
            ],
          },
        ],
      },
      rows: [
        {
          id: 1,
          name: "Cut Player",
          player_ids: ["123"],
          affiliation: "Test Club",
          tournament_id: 1,
          summary: {
            position: "CUT",
            player: "Cut Player",
          },
          rounds: {
            101 => { thru: "F", score: "+16", total: "88", status: "completed" },
            102 => { thru: "F", score: "+2", total: "74", status: "completed" },
            103 => { thru: "", score: "", total: "", status: "no_holes" },
            104 => { thru: "", score: "", total: "", status: "no_holes" },
          },
        },
      ],
    }

    GolfGenius::Scoreboard::Tournament.new(tournament_data)
  end

  def create_tournament_with_wd_player
    tournament_data = {
      meta: {
        tournament_id: 1,
        name: "Test Tournament",
        cut_text: nil,
        adjusted: false,
        rounds: [
          { id: 101, name: "R1", date: "2026-03-15", in_progress: false },
          { id: 102, name: "R2", date: "2026-03-16", in_progress: false },
          { id: 103, name: "R3", date: "2026-03-17", in_progress: false },
        ],
      },
      columns: {
        summary: [
          { key: :position, format: "position", label: "Pos", index: 0 },
          { key: :player, format: "player", label: "Player", index: 1 },
        ],
        rounds: [
          {
            round_id: 101,
            round_name: "R1",
            columns: [
              { key: :total, format: "round-total", label: "R1", index: 2, round_id: 101, round_name: "R1" },
            ],
          },
          {
            round_id: 102,
            round_name: "R2",
            columns: [
              { key: :total, format: "round-total", label: "R2", index: 3, round_id: 102, round_name: "R2" },
            ],
          },
          {
            round_id: 103,
            round_name: "R3",
            columns: [
              { key: :total, format: "round-total", label: "R3", index: 4, round_id: 103, round_name: "R3" },
            ],
          },
        ],
      },
      rows: [
        {
          id: 1,
          name: "WD Player",
          player_ids: ["456"],
          affiliation: "Test Club",
          tournament_id: 1,
          summary: {
            position: "WD",
            player: "WD Player",
          },
          rounds: {
            101 => {
              thru: "F", score: "-4", total: "68", status: "completed",
              scorecard: { thru: "F", gross_scores: Array.new(18) { 4 } },
            },
            102 => {
              thru: "", score: "", total: "", status: "no_holes",
              scorecard: { thru: "", gross_scores: [] },
            },
            103 => {
              thru: "", score: "", total: "", status: "no_holes",
              scorecard: { thru: "", gross_scores: [] },
            },
          },
        },
      ],
    }

    GolfGenius::Scoreboard::Tournament.new(tournament_data)
  end

  def create_tournament_with_historical_rounds_missing_metadata
    # Simulates a tournament where R1 and R2 are complete with score data,
    # but have empty thru/status fields (common scenario in some Golf Genius exports).
    # R3 is currently in progress.
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
        ],
        rounds: [
          {
            round_id: 101,
            round_name: "R1",
            columns: [
              { key: :total, format: "round-total", label: "R1", index: 2, round_id: 101, round_name: "R1" },
            ],
          },
          {
            round_id: 102,
            round_name: "R2",
            columns: [
              { key: :total, format: "round-total", label: "R2", index: 3, round_id: 102, round_name: "R2" },
            ],
          },
          {
            round_id: 103,
            round_name: "R3",
            columns: [
              { key: :total, format: "round-total", label: "R3", index: 4, round_id: 103, round_name: "R3" },
            ],
          },
        ],
      },
      rows: [
        {
          id: 1,
          name: "Test Player",
          player_ids: ["777"],
          affiliation: "Test Club",
          tournament_id: 1,
          summary: {
            position: "5",
            player: "Test Player",
          },
          rounds: {
            # Historical rounds with data but missing metadata (the bug scenario)
            101 => { thru: "", score: "", total: "72", status: "" },
            102 => { thru: "", score: "", total: "68", status: "" },
            # Current round with proper metadata
            103 => { thru: "9", score: "E", total: "36", status: "partial" },
          },
        },
      ],
    }

    GolfGenius::Scoreboard::Tournament.new(tournament_data)
  end

  def create_tournament_with_playing_player
    tournament_data = {
      meta: {
        tournament_id: 1,
        name: "Test Tournament",
        cut_text: nil,
        adjusted: false,
        rounds: [
          { id: 101, name: "R1", date: "2026-03-15", in_progress: false },
          { id: 102, name: "R2", date: "2026-03-16", in_progress: true },
        ],
      },
      columns: {
        summary: [],
        rounds: [],
      },
      rows: [
        {
          id: 1,
          name: "Playing Player",
          player_ids: ["789"],
          affiliation: "Test Club",
          tournament_id: 1,
          summary: {},
          rounds: {
            101 => { thru: "F", score: "E", total: "72", status: "completed" },
            102 => { thru: "8", score: "-2", total: "34", status: "partial" },
          },
        },
      ],
    }

    GolfGenius::Scoreboard::Tournament.new(tournament_data)
  end

  def create_tournament_with_finished_player
    tournament_data = {
      meta: {
        tournament_id: 1,
        name: "Test Tournament",
        cut_text: nil,
        adjusted: false,
        rounds: [
          { id: 101, name: "R1", date: "2026-03-15", in_progress: false },
          { id: 102, name: "R2", date: "2026-03-16", in_progress: true },
        ],
      },
      columns: {
        summary: [],
        rounds: [],
      },
      rows: [
        {
          id: 1,
          name: "Finished Player",
          player_ids: ["999"],
          affiliation: "Test Club",
          tournament_id: 1,
          summary: {},
          rounds: {
            101 => { thru: "F", score: "E", total: "72", status: "completed" },
            102 => { thru: "F", score: "-1", total: "71", status: "completed" },
          },
        },
      ],
    }

    GolfGenius::Scoreboard::Tournament.new(tournament_data)
  end

  def create_tournament_with_not_started_player
    tournament_data = {
      meta: {
        tournament_id: 1,
        name: "Test Tournament",
        cut_text: nil,
        adjusted: false,
        rounds: [
          { id: 101, name: "R1", date: "2026-03-15", in_progress: false },
          { id: 102, name: "R2", date: "2026-03-16", in_progress: true },
        ],
      },
      columns: {
        summary: [],
        rounds: [],
      },
      rows: [
        {
          id: 1,
          name: "Not Started Player",
          player_ids: ["888"],
          affiliation: "Test Club",
          tournament_id: 1,
          summary: {},
          rounds: {
            101 => { thru: "F", score: "E", total: "72", status: "completed" },
            102 => { thru: "", score: "", total: "", status: "no_holes" },
          },
        },
      ],
    }

    GolfGenius::Scoreboard::Tournament.new(tournament_data)
  end

  def create_tournament_with_no_active_round
    tournament_data = {
      meta: {
        tournament_id: 1,
        name: "Test Tournament",
        cut_text: nil,
        adjusted: false,
        rounds: [
          { id: 101, name: "R1", date: "2026-03-15", in_progress: false },
          { id: 102, name: "R2", date: "2026-03-16", in_progress: false },
        ],
      },
      columns: {
        summary: [],
        rounds: [],
      },
      rows: [
        {
          id: 1,
          name: "Test Player",
          player_ids: ["777"],
          affiliation: "Test Club",
          tournament_id: 1,
          summary: {},
          rounds: {
            101 => { thru: "F", score: "E", total: "72", status: "completed" },
            102 => { thru: "F", score: "-1", total: "71", status: "completed" },
          },
        },
      ],
    }

    GolfGenius::Scoreboard::Tournament.new(tournament_data)
  end
end
