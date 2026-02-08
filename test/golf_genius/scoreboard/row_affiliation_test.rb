# frozen_string_literal: true

require "test_helper"

class RowAffiliationTest < Minitest::Test
  # Test affiliations accessor
  def test_affiliations_for_individual
    row = create_row("Columbus, OH")

    affiliations = row.affiliations

    assert_equal 1, affiliations.length
    assert_instance_of GolfGenius::Scoreboard::Affiliation, affiliations.first
    assert_equal "Columbus", affiliations.first.city
    assert_equal "OH", affiliations.first.state
  end

  def test_affiliations_for_team
    row = create_row(["Tampa", "Columbus, OH"])

    affiliations = row.affiliations

    assert_equal 2, affiliations.length
    assert_equal "Tampa", affiliations[0].city
    assert_nil affiliations[0].state
    assert_equal "Columbus", affiliations[1].city
    assert_equal "OH", affiliations[1].state
  end

  def test_affiliations_with_club_name
    row = create_row("Scioto Country Club")

    affiliation = row.affiliations.first

    assert_equal "Scioto Country Club", affiliation.city
    assert_nil affiliation.state
    assert_equal "Scioto Country Club", affiliation.full
  end

  def test_affiliations_returns_empty_array_when_no_affiliation
    row = create_row(nil)

    assert_empty row.affiliations
  end

  def test_affiliation_accessible_via_player
    row = create_row("Columbus, OH")

    player = row.players.first

    assert_instance_of GolfGenius::Scoreboard::Affiliation, player.affiliation
    assert_equal "Columbus", player.affiliation.city
    assert_equal "OH", player.affiliation.state
  end

  def test_affiliation_accessible_via_team_players
    row = create_row(["Tampa", "Columbus, OH"])

    players = row.players

    assert_equal 2, players.length
    assert_equal "Tampa", players[0].affiliation.city
    assert_nil players[0].affiliation.state
    assert_equal "Columbus", players[1].affiliation.city
    assert_equal "OH", players[1].affiliation.state
  end

  # Test Carmen normalization - state code
  def test_affiliation_normalizes_state_code
    row = create_row("Columbus, OH")

    affiliation = row.affiliations.first

    assert_equal "OH", affiliation.state_code
    assert_equal "Ohio", affiliation.state_name
    assert_equal "OH", affiliation.state # Alias for state_code
  end

  def test_affiliation_normalizes_different_state_codes
    row = create_row("Louisville, KY")

    affiliation = row.affiliations.first

    assert_equal "KY", affiliation.state_code
    assert_equal "Kentucky", affiliation.state_name
  end

  # Test Carmen normalization - full state name
  def test_affiliation_recognizes_full_state_name
    row = create_row("Columbus, Ohio")

    affiliation = row.affiliations.first

    assert_equal "Columbus", affiliation.city
    assert_equal "OH", affiliation.state_code
    assert_equal "Ohio", affiliation.state_name
  end

  def test_affiliation_recognizes_different_full_state_name
    row = create_row("Louisville, Kentucky")

    affiliation = row.affiliations.first

    assert_equal "Louisville", affiliation.city
    assert_equal "KY", affiliation.state_code
    assert_equal "Kentucky", affiliation.state_name
  end

  # Test state_name when no state
  def test_affiliation_state_name_nil_when_no_state
    row = create_row("Tampa")

    affiliation = row.affiliations.first

    assert_nil affiliation.state_code
    assert_nil affiliation.state_name
    assert_nil affiliation.state
  end

  # Test affiliation_full
  def test_affiliation_full_returns_raw_affiliation
    row = create_row("Columbus, OH")

    assert_equal "Columbus, OH", row.affiliation_full
  end

  def test_affiliation_full_with_club_name
    row = create_row("Scioto Country Club")

    assert_equal "Scioto Country Club", row.affiliation_full
  end

  def test_affiliation_full_returns_nil_when_no_affiliation
    row = create_row(nil)

    assert_nil row.affiliation_full
  end

  # Test affiliation_city with city/state format
  def test_affiliation_city_with_city_and_state
    row = create_row("Columbus, OH")

    assert_equal "Columbus", row.affiliation_city
  end

  def test_affiliation_city_with_multiple_word_city
    row = create_row("Mount Vernon, OH")

    assert_equal "Mount Vernon", row.affiliation_city
  end

  def test_affiliation_city_with_extra_spaces
    row = create_row("Columbus,  OH")

    assert_equal "Columbus", row.affiliation_city
  end

  # Test affiliation_city with club names (no comma)
  def test_affiliation_city_with_club_name
    row = create_row("Scioto Country Club")

    assert_equal "Scioto Country Club", row.affiliation_city
  end

  def test_affiliation_city_with_simple_city
    row = create_row("Tampa")

    assert_equal "Tampa", row.affiliation_city
  end

  # Test affiliation_city with nil
  def test_affiliation_city_returns_nil_when_no_affiliation
    row = create_row(nil)

    assert_nil row.affiliation_city
  end

  # Test affiliation_state with city/state format
  def test_affiliation_state_with_city_and_state
    row = create_row("Columbus, OH")

    assert_equal "OH", row.affiliation_state
  end

  def test_affiliation_state_with_two_letter_state
    row = create_row("Louisville, KY")

    assert_equal "KY", row.affiliation_state
  end

  def test_affiliation_state_with_extra_spaces
    row = create_row("Columbus,  OH  ")

    assert_equal "OH", row.affiliation_state
  end

  # Test affiliation_state with club names (no comma)
  def test_affiliation_state_returns_nil_for_club_name
    row = create_row("Scioto Country Club")

    assert_nil row.affiliation_state
  end

  def test_affiliation_state_returns_nil_for_simple_city
    row = create_row("Tampa")

    assert_nil row.affiliation_state
  end

  def test_affiliation_state_returns_nil_when_no_affiliation
    row = create_row(nil)

    assert_nil row.affiliation_state
  end

  # Test team affiliations (arrays)
  def test_affiliation_city_with_team_affiliations
    row = create_row(["Tampa", "Columbus, OH"])

    assert_equal %w[Tampa Columbus], row.affiliation_city
  end

  def test_affiliation_state_with_team_affiliations
    row = create_row(["Tampa", "Columbus, OH"])

    assert_equal [nil, "OH"], row.affiliation_state
  end

  def test_affiliation_city_with_team_all_city_state
    row = create_row(["Louisville, KY", "Columbus, OH"])

    assert_equal %w[Louisville Columbus], row.affiliation_city
  end

  def test_affiliation_state_with_team_all_city_state
    row = create_row(["Louisville, KY", "Columbus, OH"])

    assert_equal %w[KY OH], row.affiliation_state
  end

  def test_affiliation_city_with_team_all_clubs
    row = create_row(["Scioto CC", "Columbus CC"])

    assert_equal ["Scioto CC", "Columbus CC"], row.affiliation_city
  end

  def test_affiliation_state_with_team_all_clubs
    row = create_row(["Scioto CC", "Columbus CC"])

    assert_equal [nil, nil], row.affiliation_state
  end

  private

  def create_row(affiliation)
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

    # If affiliation is an array, create a team name; otherwise individual
    name = if affiliation.is_a?(Array)
             affiliation.length == 2 ? "John Doe + Jane Smith" : "John Doe"
           else
             "John Doe"
           end

    player_ids = affiliation.is_a?(Array) ? %w[123 456] : ["123"]

    row_data = {
      id: 1,
      name: name,
      player_ids: player_ids,
      affiliation: affiliation,
      tournament_id: 1,
      summary: {},
      rounds: {},
    }

    GolfGenius::Scoreboard::Row.new(row_data, tournament)
  end
end
