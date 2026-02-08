# frozen_string_literal: true

require "test_helper"

class RowDecomposerTest < Minitest::Test
  def test_decompose_preserves_row_metadata
    row = {
      id: 1001,
      name: "Player A",
      player_ids: ["101"],
      affiliation: "City A",
      cut: false,
      cells: ["1", "Player A"],
      rounds: {},
    }

    column_structure = {
      summary: [],
      rounds: [],
    }

    decomposer = GolfGenius::Scoreboard::RowDecomposer.new(row, column_structure)
    result = decomposer.decompose

    assert_equal 1001, result[:id]
    assert_equal "Player A", result[:name]
    assert_equal ["101"], result[:player_ids]
    assert_equal "City A", result[:affiliation]
    assert_equal false, result[:cut]
  end

  def test_decompose_maps_summary_cells
    row = {
      id: 1001,
      name: "Player A",
      player_ids: ["101"],
      affiliation: "City A",
      cut: false,
      cells: ["1", "Player A", "+8", "88"],
      rounds: {},
    }

    column_structure = {
      summary: [
        { key: "position", format: "position", label: "Pos.", index: 0 },
        { key: "player", format: "player", label: "Player", index: 1 },
        { key: "total_to_par_gross", format: "total-to-par-gross", label: "Total", index: 2 },
        { key: "total_gross", format: "total-gross", label: "Gross", index: 3 },
      ],
      rounds: [],
    }

    decomposer = GolfGenius::Scoreboard::RowDecomposer.new(row, column_structure)
    result = decomposer.decompose

    assert_equal "1", result[:summary][:position]
    assert_equal "Player A", result[:summary][:player]
    assert_equal "+8", result[:summary][:total_to_par_gross]
    assert_equal "88", result[:summary][:total_gross]
  end

  def test_decompose_maps_round_cells
    row = {
      id: 1001,
      name: "Player A",
      player_ids: ["101"],
      affiliation: "City A",
      cut: false,
      cells: ["1", "Player A", "8", "-8", "88"],
      rounds: {},
    }

    column_structure = {
      summary: [
        { key: "position", format: "position", label: "Pos.", index: 0 },
        { key: "player", format: "player", label: "Player", index: 1 },
      ],
      rounds: [
        {
          id: 2001,
          name: "R2",
          in_progress: true,
          columns: [
            { key: "thru", format: "thru", label: "Thru R2", index: 2 },
            { key: "to_par_gross", format: "to-par-gross", label: "To Par R2", index: 3 },
          ],
        },
        {
          id: 2000,
          name: "R1",
          in_progress: false,
          columns: [
            { key: "total", format: "round-total", label: "R1", index: 4 },
          ],
        },
      ],
    }

    decomposer = GolfGenius::Scoreboard::RowDecomposer.new(row, column_structure)
    result = decomposer.decompose

    # R2 cells
    assert result[:rounds].key?(2001)
    assert_equal "8", result[:rounds][2001][:thru]
    assert_equal "-8", result[:rounds][2001][:to_par_gross]

    # R1 cells
    assert result[:rounds].key?(2000)
    assert_equal "88", result[:rounds][2000][:total]
  end

  def test_decompose_merges_scorecard_data
    row = {
      id: 1001,
      name: "Player A",
      player_ids: ["101"],
      affiliation: "City A",
      cut: false,
      cells: ["1", "Player A"],
      rounds: {
        2001 => {
          scorecard: {
            thru: "8",
            score: "-8",
            status: "partial",
            gross_scores: [4, 3, 3, 4, 2, 3, 3, 2, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
          },
        },
      },
    }

    column_structure = {
      summary: [],
      rounds: [
        {
          id: 2001,
          name: "R2",
          in_progress: true,
          columns: [],
        },
      ],
    }

    decomposer = GolfGenius::Scoreboard::RowDecomposer.new(row, column_structure)
    result = decomposer.decompose

    assert result[:rounds][2001].key?(:scorecard)
    scorecard = result[:rounds][2001][:scorecard]

    assert_equal "8", scorecard[:thru]
    assert_equal "-8", scorecard[:score]
    assert_equal "partial", scorecard[:status]
    assert_equal 18, scorecard[:gross_scores].length
  end

  def test_decompose_skips_rounds_with_no_data
    row = {
      id: 1001,
      name: "Player A",
      player_ids: ["101"],
      affiliation: "City A",
      cut: false,
      cells: ["1", "Player A"],
      rounds: {},
    }

    column_structure = {
      summary: [],
      rounds: [
        {
          id: 2001,
          name: "R2",
          in_progress: true,
          columns: [],
        },
      ],
    }

    decomposer = GolfGenius::Scoreboard::RowDecomposer.new(row, column_structure)
    result = decomposer.decompose

    # Round has no HTML columns and no JSON data, so it should be skipped
    refute result[:rounds].key?(2001)
  end

  # Data Cleaning Tests
  # Golf Genius API sometimes returns bad data in unplayed rounds for eliminated players

  def test_cleans_duplicate_total_for_cut_player
    # Bug: Golf Genius returns tournament total in unplayed round field
    row = {
      id: 1001,
      name: "Cut Player",
      player_ids: ["101"],
      affiliation: "City A",
      cut: true,
      cells: ["CUT", "Cut Player", "162", "75", "87", "162"],
      rounds: {},
    }

    column_structure = {
      summary: [
        { key: "position", format: "position", label: "Pos.", index: 0 },
        { key: "player", format: "player", label: "Player", index: 1 },
        { key: "total_gross", format: "total-gross", label: "Total", index: 2 },
      ],
      rounds: [
        { id: 101, name: "R1", in_progress: false, columns: [{ key: "total", format: "round-total", label: "R1", index: 3 }] },
        { id: 102, name: "R2", in_progress: false, columns: [{ key: "total", format: "round-total", label: "R2", index: 4 }] },
        { id: 103, name: "R3", in_progress: false, columns: [{ key: "total", format: "round-total", label: "R3", index: 5 }] },
      ],
    }

    decomposer = GolfGenius::Scoreboard::RowDecomposer.new(row, column_structure)
    result = decomposer.decompose

    assert_equal "75", result[:rounds][101][:total], "R1 should have actual score"
    assert_equal "87", result[:rounds][102][:total], "R2 should have actual score"
    assert_nil result[:rounds][103][:total], "R3 should be nil (duplicate cleaned)"
  end

  def test_cleans_status_code_in_total_for_cut_player
    # Bug: Golf Genius returns status code instead of score
    row = {
      id: 1001,
      name: "Cut Player",
      player_ids: ["101"],
      affiliation: "City A",
      cut: true,
      cells: ["CUT", "Cut Player", "162", "75", "87", "CUT"],
      rounds: {},
    }

    column_structure = {
      summary: [
        { key: "position", format: "position", label: "Pos.", index: 0 },
        { key: "player", format: "player", label: "Player", index: 1 },
        { key: "total_gross", format: "total-gross", label: "Total", index: 2 },
      ],
      rounds: [
        { id: 101, name: "R1", in_progress: false, columns: [{ key: "total", format: "round-total", label: "R1", index: 3 }] },
        { id: 102, name: "R2", in_progress: false, columns: [{ key: "total", format: "round-total", label: "R2", index: 4 }] },
        { id: 103, name: "R3", in_progress: false, columns: [{ key: "total", format: "round-total", label: "R3", index: 5 }] },
      ],
    }

    decomposer = GolfGenius::Scoreboard::RowDecomposer.new(row, column_structure)
    result = decomposer.decompose

    assert_equal "75", result[:rounds][101][:total], "R1 should have actual score"
    assert_equal "87", result[:rounds][102][:total], "R2 should have actual score"
    assert_nil result[:rounds][103][:total], "R3 should be nil (status code cleaned)"
  end

  def test_cleans_various_status_codes
    # Test all known status codes: CUT, DQ, MC, NS, NC
    status_codes = %w[CUT DQ MC NS NC]

    status_codes.each do |status|
      row = {
        id: 1001,
        name: "Eliminated Player",
        player_ids: ["101"],
        affiliation: "City A",
        cut: true,
        cells: [status, "Player", "75", "75", status],
        rounds: {},
      }

      column_structure = {
        summary: [
          { key: "position", format: "position", label: "Pos.", index: 0 },
          { key: "player", format: "player", label: "Player", index: 1 },
          { key: "total_gross", format: "total-gross", label: "Total", index: 2 },
        ],
        rounds: [
          { id: 101, name: "R1", in_progress: false, columns: [{ key: "total", format: "round-total", label: "R1", index: 3 }] },
          { id: 102, name: "R2", in_progress: false, columns: [{ key: "total", format: "round-total", label: "R2", index: 4 }] },
        ],
      }

      decomposer = GolfGenius::Scoreboard::RowDecomposer.new(row, column_structure)
      result = decomposer.decompose

      assert_nil result[:rounds][102][:total], "R2 should be nil for status code: #{status}"
    end
  end

  def test_does_not_clean_wd_player_data
    # WD players have different rules - their data should NOT be cleaned
    row = {
      id: 1001,
      name: "WD Player",
      player_ids: ["101"],
      affiliation: "City A",
      cut: false,
      cells: ["WD", "WD Player", "75", "75", "WD"],
      rounds: {},
    }

    column_structure = {
      summary: [
        { key: "position", format: "position", label: "Pos.", index: 0 },
        { key: "player", format: "player", label: "Player", index: 1 },
        { key: "total_gross", format: "total-gross", label: "Total", index: 2 },
      ],
      rounds: [
        { id: 101, name: "R1", in_progress: false, columns: [{ key: "total", format: "round-total", label: "R1", index: 3 }] },
        { id: 102, name: "R2", in_progress: false, columns: [{ key: "total", format: "round-total", label: "R2", index: 4 }] },
      ],
    }

    decomposer = GolfGenius::Scoreboard::RowDecomposer.new(row, column_structure)
    result = decomposer.decompose

    # WD data should NOT be cleaned even though it matches tournament total
    assert_equal "75", result[:rounds][101][:total], "R1 should have actual score"
    assert_equal "WD", result[:rounds][102][:total], "R2 should keep WD (not cleaned)"
  end

  def test_preserves_legitimate_competing_player_data
    # Competing players with valid, distinct round scores should not be cleaned
    row = {
      id: 1001,
      name: "Competing Player",
      player_ids: ["101"],
      affiliation: "City A",
      cut: false,
      cells: %w[5 Player 213 72 70 71],
      rounds: {},
    }

    column_structure = {
      summary: [
        { key: "position", format: "position", label: "Pos.", index: 0 },
        { key: "player", format: "player", label: "Player", index: 1 },
        { key: "total_gross", format: "total-gross", label: "Total", index: 2 },
      ],
      rounds: [
        { id: 101, name: "R1", in_progress: false, columns: [{ key: "total", format: "round-total", label: "R1", index: 3 }] },
        { id: 102, name: "R2", in_progress: false, columns: [{ key: "total", format: "round-total", label: "R2", index: 4 }] },
        { id: 103, name: "R3", in_progress: false, columns: [{ key: "total", format: "round-total", label: "R3", index: 5 }] },
      ],
    }

    decomposer = GolfGenius::Scoreboard::RowDecomposer.new(row, column_structure)
    result = decomposer.decompose

    # All scores should be preserved — none match the tournament total
    assert_equal "72", result[:rounds][101][:total], "R1 should have actual score"
    assert_equal "70", result[:rounds][102][:total], "R2 should have actual score"
    assert_equal "71", result[:rounds][103][:total], "R3 should have actual score"
  end

  def test_cleans_duplicate_total_for_competing_player
    # Competing player who hasn't started R3: the data source puts the
    # cumulative tournament total (195) into the R3 strokes cell.
    row = {
      id: 1001,
      name: "Travis Fulton",
      player_ids: ["101"],
      affiliation: "City A",
      cut: false,
      cells: ["3", "Travis Fulton", "195", "113", "82", "195"],
      rounds: {},
    }

    column_structure = {
      summary: [
        { key: "position", format: "position", label: "Pos.", index: 0 },
        { key: "player", format: "player", label: "Player", index: 1 },
        { key: "total_gross", format: "total-gross", label: "Total", index: 2 },
      ],
      rounds: [
        { id: 101, name: "R1", in_progress: false, columns: [{ key: "total", format: "round-total", label: "R1", index: 3 }] },
        { id: 102, name: "R2", in_progress: false, columns: [{ key: "total", format: "round-total", label: "R2", index: 4 }] },
        { id: 103, name: "R3", in_progress: true, columns: [{ key: "total", format: "round-total", label: "R3", index: 5 }] },
      ],
    }

    decomposer = GolfGenius::Scoreboard::RowDecomposer.new(row, column_structure)
    result = decomposer.decompose

    assert_equal "113", result[:rounds][101][:total], "R1 should have actual score"
    assert_equal "82", result[:rounds][102][:total], "R2 should have actual score"
    assert_nil result[:rounds][103][:total], "R3 should be nil (duplicate total cleaned)"
  end

  def test_normalize_cell_value_converts_dashes_to_nil
    # RowDecomposer normalizes HTML "-" placeholders to nil so downstream
    # code doesn't need to handle display artifacts from the source.
    row = {
      id: 1001,
      name: "Player A",
      player_ids: ["101"],
      affiliation: "City A",
      cut: false,
      cells: ["5", "Player A", "-", "72"],
      rounds: {},
    }

    column_structure = {
      summary: [
        { key: "position", format: "position", label: "Pos.", index: 0 },
        { key: "player", format: "player", label: "Player", index: 1 },
        { key: "total_to_par_gross", format: "total-to-par-gross", label: "To Par", index: 2 },
        { key: "total_gross", format: "total-gross", label: "Total", index: 3 },
      ],
      rounds: [],
    }

    decomposer = GolfGenius::Scoreboard::RowDecomposer.new(row, column_structure)
    result = decomposer.decompose

    assert_equal "5", result[:summary][:position]
    assert_equal "Player A", result[:summary][:player]
    refute result[:summary].key?(:total_to_par_gross), "Dash should be normalized to nil and excluded"
    assert_equal "72", result[:summary][:total_gross]
  end

  def test_cleans_only_rounds_for_eliminated_players
    # Multiple status codes that trigger cleaning
    eliminated_statuses = %w[CUT MC DQ NS NC]

    eliminated_statuses.each do |status|
      row = {
        id: 1001,
        name: "Eliminated Player",
        player_ids: ["101"],
        affiliation: "City A",
        cut: true,
        cells: [status, "Player", "162", "75", "87", "162"],
        rounds: {},
      }

      column_structure = {
        summary: [
          { key: "position", format: "position", label: "Pos.", index: 0 },
          { key: "player", format: "player", label: "Player", index: 1 },
          { key: "total_gross", format: "total-gross", label: "Total", index: 2 },
        ],
        rounds: [
          { id: 101, name: "R1", in_progress: false, columns: [{ key: "total", format: "round-total", label: "R1", index: 3 }] },
          { id: 102, name: "R2", in_progress: false, columns: [{ key: "total", format: "round-total", label: "R2", index: 4 }] },
          { id: 103, name: "R3", in_progress: false, columns: [{ key: "total", format: "round-total", label: "R3", index: 5 }] },
        ],
      }

      decomposer = GolfGenius::Scoreboard::RowDecomposer.new(row, column_structure)
      result = decomposer.decompose

      assert_equal "75", result[:rounds][101][:total], "R1 should have actual score for #{status}"
      assert_equal "87", result[:rounds][102][:total], "R2 should have actual score for #{status}"
      assert_nil result[:rounds][103][:total], "R3 duplicate should be cleaned for #{status}"
    end
  end
end
