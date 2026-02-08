# frozen_string_literal: true

require "test_helper"

class TournamentMetadataTest < Minitest::Test
  # Test rounds.current
  def test_rounds_current_returns_in_progress_round
    tournament = create_tournament(
      rounds: [
        { id: 101, name: "R1", in_progress: false, date: "2026-03-15" },
        { id: 102, name: "R2", in_progress: true, date: "2026-03-16" },
        { id: 103, name: "R3", in_progress: false, date: "2026-03-17" },
      ]
    )

    current = tournament.rounds.current

    assert_equal 102, current.id
    assert_equal "R2", current.name
    assert_predicate current, :playing?
  end

  def test_rounds_current_returns_nil_when_no_round_in_progress
    tournament = create_tournament(
      rounds: [
        { id: 101, name: "R1", in_progress: false, date: "2026-03-15" },
        { id: 102, name: "R2", in_progress: false, date: "2026-03-16" },
      ]
    )

    assert_nil tournament.rounds.current
  end

  def test_rounds_current_returns_first_when_multiple_in_progress
    tournament = create_tournament(
      rounds: [
        { id: 101, name: "R1", in_progress: true, date: "2026-03-15" },
        { id: 102, name: "R2", in_progress: true, date: "2026-03-16" },
      ]
    )

    current = tournament.rounds.current

    # Should return first match
    assert_equal 101, current.id
  end

  # Test rounds.size
  def test_rounds_size_returns_round_count
    tournament = create_tournament(
      rounds: [
        { id: 101, name: "R1", in_progress: false, date: "2026-03-15" },
        { id: 102, name: "R2", in_progress: false, date: "2026-03-16" },
        { id: 103, name: "R3", in_progress: false, date: "2026-03-17" },
        { id: 104, name: "R4", in_progress: false, date: "2026-03-18" },
      ]
    )

    assert_equal 4, tournament.rounds.size
  end

  # Test cut_line_text
  def test_cut_line_text_returns_text_from_metadata
    tournament = create_tournament(
      cut_text: "The following players did not make the cut"
    )

    assert_equal "The following players did not make the cut", tournament.cut_line_text
  end

  def test_cut_line_text_returns_nil_when_not_present
    tournament = create_tournament(cut_text: nil)

    assert_nil tournament.cut_line_text
  end

  # Test cut_players?
  def test_cut_players_returns_true_when_cut_players_exist
    tournament = create_tournament_with_rows(
      rows: [
        { position: "1", name: "John Doe" },
        { position: "CUT", name: "Jane Smith" },
        { position: "T3", name: "Bob Jones" },
      ]
    )

    assert_predicate tournament, :cut_players?
  end

  def test_cut_players_returns_true_when_wd_players_exist
    tournament = create_tournament_with_rows(
      rows: [
        { position: "1", name: "John Doe" },
        { position: "WD", name: "Jane Smith" },
      ]
    )

    assert_predicate tournament, :cut_players?
  end

  def test_cut_players_returns_false_when_no_cut_players
    tournament = create_tournament_with_rows(
      rows: [
        { position: "1", name: "John Doe" },
        { position: "T2", name: "Jane Smith" },
        { position: "3", name: "Bob Jones" },
      ]
    )

    refute_predicate tournament, :cut_players?
  end

  def test_cut_players_returns_false_for_empty_tournament
    tournament = create_tournament_with_rows(rows: [])

    refute_predicate tournament, :cut_players?
  end

  private

  def create_tournament(rounds: [], cut_text: nil)
    data = {
      meta: {
        tournament_id: 1,
        name: "Test Tournament",
        cut_text: cut_text,
        adjusted: false,
        rounds: rounds,
      },
      columns: {
        summary: [],
        rounds: [],
      },
      rows: [],
    }

    GolfGenius::Scoreboard::Tournament.new(data)
  end

  def create_tournament_with_rows(rows:)
    data = {
      meta: {
        tournament_id: 1,
        name: "Test Tournament",
        cut_text: nil,
        adjusted: false,
        rounds: [],
      },
      columns: {
        summary: [
          { key: :position, format: "position", label: "Pos", index: 0 },
          { key: :player, format: "player", label: "Player", index: 1 },
        ],
        rounds: [],
      },
      rows: rows.map do |row_data|
        {
          id: rand(1000),
          name: row_data[:name],
          player_ids: ["123"],
          affiliation: nil,
          tournament_id: 1,
          summary: { position: row_data[:position] },
          rounds: {},
        }
      end,
    }

    GolfGenius::Scoreboard::Tournament.new(data)
  end
end
