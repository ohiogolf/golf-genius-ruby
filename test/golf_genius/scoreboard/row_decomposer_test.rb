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
end
