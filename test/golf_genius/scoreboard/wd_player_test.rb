# frozen_string_literal: true

require "test_helper"

class WdPlayerTest < Minitest::Test
  # Tests for WD (withdrawn) player display logic and convenience methods

  def test_wd_player_shows_nil_for_unplayed_rounds
    # Player completed R1 (75), withdrew before R2 (never started R2 or R3).
    # Only rounds with hole-by-hole data show "WD". Unplayed rounds show nil (dash).
    tournament = create_wd_tournament([
                                        { id: 101, total: "75", thru: "F" }, # Played R1
                                        { id: 102, total: "WD", thru: "" },  # Withdrew before R2
                                        { id: 103, total: "", thru: "" },    # Never played R3
                                      ])

    row = tournament.rows.first
    cells = row.cells

    r1_cell = cells.find { |c| c.column.round_name == "R1" && c.column.strokes? }
    r2_cell = cells.find { |c| c.column.round_name == "R2" && c.column.strokes? }
    r3_cell = cells.find { |c| c.column.round_name == "R3" && c.column.strokes? }

    assert_equal "75", r1_cell.value, "R1 should show actual score"
    assert_nil r2_cell.value, "R2 should be nil (never started)"
    assert_nil r3_cell.value, "R3 should be nil (never played)"
  end

  def test_wd_player_shows_wd_for_started_withdrawal_round
    # Player completed R1, withdrew during R2 (has hole data for R2).
    # R2 shows "WD", R3 shows nil (never played).
    tournament = create_wd_tournament([
                                        { id: 101, total: "73", thru: "F" }, # Played R1
                                        { id: 102, total: "WD", thru: "9" }, # WD during R2
                                        { id: 103, total: "", thru: "" },    # Never played R3
                                      ])

    row = tournament.rows.first
    cells = row.cells

    r1_cell = cells.find { |c| c.column.round_name == "R1" && c.column.strokes? }
    r2_cell = cells.find { |c| c.column.round_name == "R2" && c.column.strokes? }
    r3_cell = cells.find { |c| c.column.round_name == "R3" && c.column.strokes? }

    assert_equal "73", r1_cell.value, "R1 should show actual score"
    assert_equal "WD", r2_cell.value, "R2 should show WD (withdrew during round)"
    assert_nil r3_cell.value, "R3 should be nil (never played)"
  end

  def test_wd_player_shows_score_and_wd_for_later_withdrawal
    # Player completed R1 and R2, withdrew during R3 (has hole data for R3).
    # R3 shows "WD", R4 shows nil (never played).
    tournament = create_wd_tournament([
                                        { id: 101, total: "73", thru: "F" }, # Played R1
                                        { id: 102, total: "73", thru: "F" }, # Played R2
                                        { id: 103, total: "WD", thru: "9" }, # WD during R3
                                        { id: 104, total: "WD", thru: "" },  # Never played R4
                                      ])

    row = tournament.rows.first
    cells = row.cells

    r1_cell = cells.find { |c| c.column.round_name == "R1" && c.column.strokes? }
    r2_cell = cells.find { |c| c.column.round_name == "R2" && c.column.strokes? }
    r3_cell = cells.find { |c| c.column.round_name == "R3" && c.column.strokes? }
    r4_cell = cells.find { |c| c.column.round_name == "R4" && c.column.strokes? }

    assert_equal "73", r1_cell.value, "R1 should show actual score"
    assert_equal "73", r2_cell.value, "R2 should show actual score"
    assert_equal "WD", r3_cell.value, "R3 should show WD (withdrew during round)"
    assert_nil r4_cell.value, "R4 should be nil (never played)"
  end

  def test_wd_player_summary_strokes_shows_wd
    tournament = create_wd_tournament([
                                        { id: 101, total: "75", thru: "F" },
                                        { id: 102, total: "WD", thru: "" },
                                      ])

    row = tournament.rows.first
    cells = row.cells

    # Summary strokes column should show "WD"
    total_cell = cells.find { |c| c.column.summary? && c.column.strokes? }

    assert_equal "WD", total_cell.value
  end

  def test_wd_player_summary_to_par_shows_nil
    tournament = create_wd_tournament([
                                        { id: 101, total: "75", thru: "F" },
                                        { id: 102, total: "WD", thru: "" },
                                      ])

    row = tournament.rows.first
    cells = row.cells

    # Summary to-par column should be nil (renders as "-")
    to_par_cell = cells.find { |c| c.column.summary? && c.column.to_par? }

    assert_nil to_par_cell.value
  end

  def test_elimination_round_id_returns_last_played_round_for_wd
    tournament = create_wd_tournament([
                                        { id: 101, total: "75", thru: "F" },
                                        { id: 102, total: "WD", thru: "" },
                                        { id: 103, total: "", thru: "" },
                                      ])

    row = tournament.rows.first

    assert_equal 101, row.elimination_round_id, "Should return R1 (last played round)"
  end

  def test_elimination_round_id_returns_wd_round_when_started
    tournament = create_wd_tournament([
                                        { id: 101, total: "73", thru: "F" },
                                        { id: 102, total: "WD", thru: "9" }, # WD during round
                                        { id: 103, total: "", thru: "" },
                                      ])

    row = tournament.rows.first

    assert_equal 102, row.elimination_round_id, "Should return R2 (WD round with thru data)"
  end

  def test_elimination_round_id_returns_nil_for_competing_player
    tournament = create_tournament_with_competing_player

    row = tournament.rows.first

    assert_nil row.elimination_round_id
  end

  def test_elimination_round_returns_round_object
    tournament = create_wd_tournament([
                                        { id: 101, total: "75", thru: "F" },
                                        { id: 102, total: "WD", thru: "" },
                                      ])

    row = tournament.rows.first
    elimination_round = row.elimination_round

    refute_nil elimination_round
    assert_equal "R1", elimination_round.name
    assert_equal 101, elimination_round.id
  end

  def test_elimination_round_returns_nil_for_competing_player
    tournament = create_tournament_with_competing_player

    row = tournament.rows.first

    assert_nil row.elimination_round
  end

  def test_elimination_round_works_for_cut_player
    tournament = create_cut_tournament

    row = tournament.rows.first
    elimination_round = row.elimination_round

    refute_nil elimination_round
    assert_equal "R2", elimination_round.name
    assert_equal 102, elimination_round.id
  end

  private

  def create_wd_tournament(rounds_data)
    rounds_hash = {}
    rounds_data.each do |round|
      thru = round[:thru]
      round_started = thru && !thru.to_s.strip.empty?

      rounds_hash[round[:id]] = {
        thru: thru,
        total: round[:total],
        score: "",
        status: thru == "F" ? "completed" : "partial",
        scorecard: {
          thru: thru,
          gross_scores: round_started ? Array.new(18) { 4 } : [],
        },
      }
    end

    create_tournament(position: "WD", rounds: rounds_hash)
  end

  def create_cut_tournament
    create_tournament(
      position: "CUT",
      rounds: {
        101 => {
          thru: "F",
          total: "88",
          score: "+16",
          status: "completed",
          scorecard: { thru: "F" },
        },
        102 => {
          thru: "F",
          total: "74",
          score: "+2",
          status: "completed",
          scorecard: { thru: "F" },
        },
        103 => {
          thru: "",
          total: "",
          score: "",
          status: "no_holes",
          scorecard: { thru: "" },
        },
      }
    )
  end

  def create_tournament_with_competing_player
    create_tournament(
      position: "5",
      rounds: {
        101 => {
          thru: "F",
          total: "72",
          score: "E",
          status: "completed",
          scorecard: { thru: "F" },
        },
        102 => {
          thru: "F",
          total: "70",
          score: "-2",
          status: "completed",
          scorecard: { thru: "F" },
        },
        103 => {
          thru: "F",
          total: "71",
          score: "-1",
          status: "completed",
          scorecard: { thru: "F" },
        },
      }
    )
  end

  def create_tournament(position:, rounds:)
    tournament_data = {
      meta: {
        tournament_id: 1,
        name: "Test Tournament",
        cut_text: nil,
        adjusted: false,
        rounds: rounds.keys.map.with_index do |id, i|
          { id: id, name: "R#{i + 1}", date: "2026-03-#{15 + i}", in_progress: false }
        end,
      },
      columns: {
        summary: [
          { key: :position, format: "position", label: "Pos", index: 0 },
          { key: :player, format: "player", label: "Player", index: 1 },
          { key: :total_gross, format: "total-gross", label: "Total", index: 2 },
          { key: :to_par, format: "total-to-par-gross", label: "To Par", index: 3 },
        ],
        rounds: rounds.keys.map.with_index do |id, i|
          {
            round_id: id,
            round_name: "R#{i + 1}",
            columns: [
              {
                key: :total,
                format: "round-total",
                label: "R#{i + 1}",
                index: 4 + i,
                round_id: id,
                round_name: "R#{i + 1}",
              },
            ],
          }
        end,
      },
      rows: [
        {
          id: 1,
          name: "Test Player",
          player_ids: ["123"],
          affiliation: "Test Club",
          tournament_id: 1,
          summary: {
            position: position,
            player: "Test Player",
            total_gross: position == "WD" ? "WD" : "213",
            to_par: "+10",
          },
          rounds: rounds,
        },
      ],
    }

    GolfGenius::Scoreboard::Tournament.new(tournament_data)
  end
end
