# frozen_string_literal: true

require "test_helper"

class RowNameTest < Minitest::Test
  # Test individual player names
  def test_first_name_for_individual_player
    row = create_row("John Doe")

    assert_equal "John", row.first_name
  end

  def test_last_name_for_individual_player
    row = create_row("John Doe")

    assert_equal "Doe", row.last_name
  end

  def test_full_name_for_individual_player
    row = create_row("John Doe")

    assert_equal "John Doe", row.full_name
  end

  def test_name_with_suffix
    row = create_row("Paul Schlimm Jr.")

    assert_equal "Paul", row.first_name
    assert_equal "Schlimm", row.last_name

    # Check via players accessor
    player = row.players.first

    assert_equal "Schlimm", player.last_name
    assert_equal "Jr.", player.suffix
  end

  def test_name_with_middle_name
    row = create_row("Robert F. Gerwin II")

    assert_equal "Robert F.", row.first_name
    assert_equal "Gerwin", row.last_name

    # Check via players accessor
    player = row.players.first

    assert_equal "Robert F.", player.first_name
    assert_equal "Gerwin", player.last_name
    assert_equal "II", player.suffix
  end

  def test_name_with_amateur_suffix_strips_it
    row = create_row("Adam Black (a)")

    assert_equal "Adam", row.first_name
    assert_equal "Black", row.last_name
    assert_equal "Adam Black (a)", row.full_name
  end

  # Test team names
  def test_first_name_for_team_returns_array
    row = create_row("John Doe + Jane Smith")

    assert_equal %w[John Jane], row.first_name
  end

  def test_last_name_for_team_returns_array
    row = create_row("John Doe + Jane Smith")

    assert_equal %w[Doe Smith], row.last_name
  end

  def test_full_name_for_team
    row = create_row("John Doe + Jane Smith")

    assert_equal "John Doe + Jane Smith", row.full_name
  end

  def test_team_with_complex_names
    row = create_row("Robert F. Gerwin II (a) + Paul Schlimm Jr.")

    assert_equal ["Robert F.", "Paul"], row.first_name
    assert_equal %w[Gerwin Schlimm], row.last_name

    # Check via players accessor
    players = row.players

    assert_equal 2, players.length

    assert_equal "Robert F.", players[0].first_name
    assert_equal "Gerwin", players[0].last_name
    assert_equal "II", players[0].suffix
    assert_predicate players[0], :amateur?

    assert_equal "Paul", players[1].first_name
    assert_equal "Schlimm", players[1].last_name
    assert_equal "Jr.", players[1].suffix
    refute_predicate players[1], :amateur?
  end

  # Test players accessor
  def test_players_for_individual
    row = create_row("John Doe")

    players = row.players

    assert_equal 1, players.length
    assert_instance_of GolfGenius::Scoreboard::Name, players.first
    assert_equal "John", players.first.first_name
    assert_equal "Doe", players.first.last_name
  end

  def test_players_for_team
    row = create_row("John Doe + Jane Smith")

    players = row.players

    assert_equal 2, players.length
    assert_equal "John", players[0].first_name
    assert_equal "Jane", players[1].first_name
  end

  def test_players_with_metadata
    row = create_row("Adam Black (a)")

    player = row.players.first

    assert_equal "Adam", player.first_name
    assert_equal "Black", player.last_name
    assert_equal ["(a)"], player.metadata
    assert_predicate player, :amateur?
    assert_equal "Adam Black (a)", player.full_name
  end

  # Test edge cases
  def test_nil_name
    row = create_row(nil)

    assert_nil row.first_name
    assert_nil row.last_name
    assert_nil row.full_name
  end

  def test_empty_name
    row = create_row("")

    assert_nil row.first_name
    assert_nil row.last_name
    assert_equal "", row.full_name
  end

  private

  def create_row(name)
    tournament_data = {
      meta: {
        tournament_id: 1,
        name: "Test Tournament",
        cut_text: nil,
        adjusted: false,
        rounds: [],
      },
      columns: {
        summary: [],
        rounds: [],
      },
      rows: [],
    }
    tournament = GolfGenius::Scoreboard::Tournament.new(tournament_data)

    row_data = {
      id: 1,
      name: name,
      player_ids: ["123"],
      affiliation: "Test Club",
      tournament_id: 1,
      summary: {},
      rounds: {},
    }

    GolfGenius::Scoreboard::Row.new(row_data, tournament)
  end
end
