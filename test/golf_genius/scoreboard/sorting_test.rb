# frozen_string_literal: true

require "test_helper"

class SortingTest < Minitest::Test
  # Test default sort (competing, then position)
  def test_sort_defaults_to_competing_then_position
    tournament = create_tournament_with_positions(
      %w[T2 1 CUT 3 WD]
    )

    sorted = tournament.sort

    positions = sorted.rows.map(&:position)

    # Competing players first (1, T2, 3), then eliminated (CUT, WD)
    assert_equal %w[1 T2 3 CUT WD], positions
  end

  # Test position sort ascending
  def test_sort_by_position_ascending
    tournament = create_tournament_with_positions(
      %w[T5 1 CUT T2 WD 3 DQ]
    )

    sorted = tournament.sort(:position)

    positions = sorted.rows.map(&:position)

    assert_equal %w[1 T2 3 T5 CUT DQ WD], positions
  end

  def test_sort_by_position_handles_numeric_positions
    tournament = create_tournament_with_positions(
      %w[15 2 45 1 8]
    )

    sorted = tournament.sort(:position)

    positions = sorted.rows.map(&:position)

    assert_equal %w[1 2 8 15 45], positions
  end

  def test_sort_by_position_handles_tied_positions
    tournament = create_tournament_with_positions(
      %w[T15 T2 T5 T2 1]
    )

    sorted = tournament.sort(:position)

    positions = sorted.rows.map(&:position)

    assert_equal %w[1 T2 T2 T5 T15], positions
  end

  def test_sort_by_position_puts_status_codes_last
    tournament = create_tournament_with_positions(
      %w[WD 1 DQ T2 CUT MC NS NC]
    )

    sorted = tournament.sort(:position)

    positions = sorted.rows.map(&:position)
    # Status codes should be last, alphabetically
    assert_equal "1", positions[0]
    assert_equal "T2", positions[1]
    assert_includes positions[2..], "CUT"
    assert_includes positions[2..], "DQ"
    assert_includes positions[2..], "MC"
    assert_includes positions[2..], "NC"
    assert_includes positions[2..], "NS"
    assert_includes positions[2..], "WD"
  end

  # Test position sort descending
  def test_sort_by_position_descending
    tournament = create_tournament_with_positions(
      %w[1 T2 3 CUT WD]
    )

    sorted = tournament.sort(:position, direction: :desc)

    positions = sorted.rows.map(&:position)
    # Descending: worst to best
    assert_equal %w[WD CUT 3 T2 1], positions
  end

  # Test last_name sort ascending
  def test_sort_by_last_name_ascending
    tournament = create_tournament_with_names(
      ["John Smith", "Alice Anderson", "Bob Zimmerman", "Charlie Brown"]
    )

    sorted = tournament.sort(:last_name)

    names = sorted.rows.map(&:last_name)

    assert_equal %w[Anderson Brown Smith Zimmerman], names
  end

  def test_sort_by_last_name_case_insensitive
    tournament = create_tournament_with_names(
      ["john SMITH", "alice anderson", "Bob Zimmerman"]
    )

    sorted = tournament.sort(:last_name)

    names = sorted.rows.map(&:last_name)

    assert_equal %w[anderson SMITH Zimmerman], names
  end

  # Test last_name sort descending
  def test_sort_by_last_name_descending
    tournament = create_tournament_with_names(
      ["Alice Anderson", "Bob Brown", "Charlie Smith"]
    )

    sorted = tournament.sort(:last_name, direction: :desc)

    names = sorted.rows.map(&:last_name)

    assert_equal %w[Smith Brown Anderson], names
  end

  # Test multi-key sort
  def test_sort_by_position_then_last_name
    tournament = create_tournament_with_data(
      [
        { position: "T2", name: "John Smith" },
        { position: "1", name: "Alice Anderson" },
        { position: "T2", name: "Bob Anderson" },
        { position: "T2", name: "Charlie Zimmerman" },
      ]
    )

    sorted = tournament.sort(:position, :last_name)

    # Should be: 1 (Anderson), T2 (Anderson), T2 (Smith), T2 (Zimmerman)
    assert_equal "1", sorted.rows[0].position
    assert_equal "Anderson", sorted.rows[0].last_name

    assert_equal "T2", sorted.rows[1].position
    assert_equal "Anderson", sorted.rows[1].last_name

    assert_equal "T2", sorted.rows[2].position
    assert_equal "Smith", sorted.rows[2].last_name

    assert_equal "T2", sorted.rows[3].position
    assert_equal "Zimmerman", sorted.rows[3].last_name
  end

  # Test immutability
  def test_sort_returns_new_tournament
    original = create_tournament_with_positions(%w[3 1 2])

    sorted = original.sort(:position)

    # Original unchanged
    assert_equal %w[3 1 2], original.rows.map(&:position)

    # Sorted has new order
    assert_equal %w[1 2 3], sorted.rows.map(&:position)

    # Different instances
    refute_same original, sorted
  end

  # Test invalid sort key
  def test_sort_raises_on_invalid_key
    tournament = create_tournament_with_positions(%w[1 2])

    error = assert_raises(ArgumentError) do
      tournament.sort(:invalid_key)
    end

    assert_match(/Unknown sort key: invalid_key/, error.message)
  end

  # Test edge cases
  def test_sort_handles_nil_positions
    tournament = create_tournament_with_positions(["1", nil, "2", ""])

    sorted = tournament.sort(:position)

    # nil and empty should sort to end
    positions = sorted.rows.map(&:position)

    assert_equal "1", positions[0]
    assert_equal "2", positions[1]
  end

  def test_sort_handles_empty_tournament
    tournament = create_tournament_with_data([])

    sorted = tournament.sort(:position)

    assert_empty sorted.rows
  end

  # Test competing sort
  def test_sort_by_competing_puts_active_players_first
    tournament = create_tournament_with_data([
                                               { position: "T2", name: "Bob Smith" },
                                               { position: "CUT", name: "Alice Anderson" },
                                               { position: "1", name: "Charlie Brown" },
                                               { position: "WD", name: "David Wilson" },
                                             ])

    sorted = tournament.sort(:competing)

    # Competing players should be first (any order)
    assert_equal "T2", sorted.rows[0].position
    assert_equal "1", sorted.rows[1].position
    # Eliminated players should be last (any order)
    assert_equal "CUT", sorted.rows[2].position
    assert_equal "WD", sorted.rows[3].position
  end

  def test_sort_by_competing_then_last_name
    tournament = create_tournament_with_data([
                                               { position: "T2", name: "Bob Smith" },
                                               { position: "CUT", name: "Alice Anderson" },
                                               { position: "1", name: "Charlie Brown" },
                                               { position: "WD", name: "David Wilson" },
                                             ])

    sorted = tournament.sort(:competing, :last_name)

    # Competing players first, alphabetically
    assert_equal "Charlie Brown", sorted.rows[0].name
    assert_equal "Bob Smith", sorted.rows[1].name
    # Eliminated players last, alphabetically
    assert_equal "Alice Anderson", sorted.rows[2].name
    assert_equal "David Wilson", sorted.rows[3].name
  end

  def test_sort_by_competing_descending
    tournament = create_tournament_with_data([
                                               { position: "1", name: "Alice Active" },
                                               { position: "CUT", name: "Bob Cut" },
                                             ])

    sorted = tournament.sort(:competing, direction: :desc)

    # Eliminated players first when descending
    assert_equal "Bob Cut", sorted.rows[0].name
    assert_equal "Alice Active", sorted.rows[1].name
  end

  def test_sort_handles_nil_last_names
    tournament = create_tournament_with_data([
                                               { position: "1", name: "Alice Anderson" },
                                               { position: "2", name: nil }, # nil name
                                               { position: "3", name: "Charlie Smith" },
                                               { position: "4", name: "" }, # empty name
                                             ])

    sorted = tournament.sort(:last_name)

    # Real names should come first, nil/empty at end
    assert_equal "Anderson", sorted.rows[0].last_name
    assert_equal "Smith", sorted.rows[1].last_name
    # Last two should be nil/empty (order doesn't matter)
    assert_nil sorted.rows[2].last_name
    assert_nil sorted.rows[3].last_name
  end

  private

  def create_tournament_with_positions(positions)
    rows = positions.map.with_index do |pos, i|
      create_row_data(position: pos, name: "Player #{i}")
    end
    create_tournament(rows)
  end

  def create_tournament_with_names(names)
    rows = names.map.with_index do |name, i|
      create_row_data(position: (i + 1).to_s, name: name)
    end
    create_tournament(rows)
  end

  def create_tournament_with_data(data_array)
    rows = data_array.map do |data|
      create_row_data(position: data[:position], name: data[:name])
    end
    create_tournament(rows)
  end

  def create_row_data(position:, name:)
    if name.nil? || name.empty?
      first = nil
      last = nil
    else
      first, last = name.split
    end

    {
      id: rand(1000),
      name: name,
      first_name: first,
      last_name: last,
      player_ids: ["123"],
      affiliation: nil,
      tournament_id: 1,
      summary: { position: position },
      rounds: {},
    }
  end

  def create_tournament(rows)
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
      rows: rows,
    }

    GolfGenius::Scoreboard::Tournament.new(data)
  end
end
