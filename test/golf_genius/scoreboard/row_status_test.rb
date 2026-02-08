# frozen_string_literal: true

require "test_helper"

class RowStatusTest < Minitest::Test
  def setup
    # Load fixtures
    @html = File.read(File.join(__dir__, "../../fixtures/tournament_results/with_cut_line.html"))
    @json = File.read(File.join(__dir__, "../../fixtures/tournament_results/with_cut_line.json"))

    # Create mock objects
    @event = Object.new
    def @event.id
      "1002"
    end

    def @event.[](key)
      [:name, "name"].include?(key) ? "Test Event" : nil
    end

    @round = Object.new
    def @round.id
      "2001"
    end

    def @round.[](key)
      case key
      when :id, "id" then "2001"
      when :name, "name" then "R1"
      end
    end

    @tournament = Object.new
    def @tournament.id
      "1002"
    end

    def @tournament.[](key)
      key == :name ? "Test Tournament" : nil
    end

    def @tournament.non_scoring?
      false
    end

    @json_obj = Object.new
    # rubocop:disable Lint/UnusedMethodArgument
    def @json_obj.to_json(raw: true)
      File.read(File.join(__dir__, "../../fixtures/tournament_results/with_cut_line.json"))
    end
    # rubocop:enable Lint/UnusedMethodArgument
  end

  def test_position_returns_position_value
    row = create_row_with_position("T2")

    assert_equal "T2", row.position
  end

  def test_position_returns_nil_when_no_position_column
    row = create_row_without_position

    assert_nil row.position
  end

  def test_cut_returns_true_for_cut_position
    row = create_row_with_position("CUT")

    assert_predicate row, :cut?
  end

  def test_cut_returns_true_for_mc_position
    row = create_row_with_position("MC")

    assert_predicate row, :cut?
  end

  def test_cut_returns_true_for_lowercase_cut
    row = create_row_with_position("cut")

    assert_predicate row, :cut?
  end

  def test_cut_returns_false_for_numeric_position
    row = create_row_with_position("1")

    refute_predicate row, :cut?
  end

  def test_cut_returns_false_for_tied_position
    row = create_row_with_position("T2")

    refute_predicate row, :cut?
  end

  def test_cut_returns_false_for_nil_position
    row = create_row_without_position

    refute_predicate row, :cut?
  end

  def test_withdrew_returns_true_for_wd_position
    row = create_row_with_position("WD")

    assert_predicate row, :withdrew?
  end

  def test_withdrew_returns_true_for_lowercase_wd
    row = create_row_with_position("wd")

    assert_predicate row, :withdrew?
  end

  def test_withdrew_returns_false_for_other_positions
    row = create_row_with_position("CUT")

    refute_predicate row, :withdrew?
  end

  def test_disqualified_returns_true_for_dq_position
    row = create_row_with_position("DQ")

    assert_predicate row, :disqualified?
  end

  def test_disqualified_returns_true_for_lowercase_dq
    row = create_row_with_position("dq")

    assert_predicate row, :disqualified?
  end

  def test_disqualified_returns_false_for_other_positions
    row = create_row_with_position("WD")

    refute_predicate row, :disqualified?
  end

  def test_no_show_returns_true_for_ns_position
    row = create_row_with_position("NS")

    assert_predicate row, :no_show?
  end

  def test_no_show_returns_true_for_lowercase_ns
    row = create_row_with_position("ns")

    assert_predicate row, :no_show?
  end

  def test_no_show_returns_false_for_other_positions
    row = create_row_with_position("CUT")

    refute_predicate row, :no_show?
  end

  def test_no_card_returns_true_for_nc_position
    row = create_row_with_position("NC")

    assert_predicate row, :no_card?
  end

  def test_no_card_returns_true_for_lowercase_nc
    row = create_row_with_position("nc")

    assert_predicate row, :no_card?
  end

  def test_no_card_returns_false_for_other_positions
    row = create_row_with_position("CUT")

    refute_predicate row, :no_card?
  end

  def test_eliminated_returns_true_for_cut
    row = create_row_with_position("CUT")

    assert_predicate row, :eliminated?
  end

  def test_eliminated_returns_true_for_mc
    row = create_row_with_position("MC")

    assert_predicate row, :eliminated?
  end

  def test_eliminated_returns_true_for_wd
    row = create_row_with_position("WD")

    assert_predicate row, :eliminated?
  end

  def test_eliminated_returns_true_for_dq
    row = create_row_with_position("DQ")

    assert_predicate row, :eliminated?
  end

  def test_eliminated_returns_true_for_ns
    row = create_row_with_position("NS")

    assert_predicate row, :eliminated?
  end

  def test_eliminated_returns_true_for_nc
    row = create_row_with_position("NC")

    assert_predicate row, :eliminated?
  end

  def test_eliminated_returns_false_for_numeric_position
    row = create_row_with_position("1")

    refute_predicate row, :eliminated?
  end

  def test_eliminated_returns_false_for_tied_position
    row = create_row_with_position("T5")

    refute_predicate row, :eliminated?
  end

  def test_eliminated_returns_false_for_nil_position
    row = create_row_without_position

    refute_predicate row, :eliminated?
  end

  def test_competing_returns_true_for_numeric_position
    row = create_row_with_position("1")

    assert_predicate row, :competing?
  end

  def test_competing_returns_true_for_tied_position
    row = create_row_with_position("T2")

    assert_predicate row, :competing?
  end

  def test_competing_returns_false_for_cut
    row = create_row_with_position("CUT")

    refute_predicate row, :competing?
  end

  def test_competing_returns_false_for_wd
    row = create_row_with_position("WD")

    refute_predicate row, :competing?
  end

  def test_competing_returns_false_for_dq
    row = create_row_with_position("DQ")

    refute_predicate row, :competing?
  end

  def test_competing_returns_false_for_ns
    row = create_row_with_position("NS")

    refute_predicate row, :competing?
  end

  def test_competing_returns_false_for_nc
    row = create_row_with_position("NC")

    refute_predicate row, :competing?
  end

  def test_competing_returns_true_for_nil_position
    # A player with no position is technically still competing
    row = create_row_without_position

    assert_predicate row, :competing?
  end

  def test_integration_with_real_fixture
    GolfGenius::Event.stub :fetch, @event do
      GolfGenius::Event.stub :rounds, [@round] do
        GolfGenius::Event.stub :tournaments, [@tournament] do
          GolfGenius::Event.stub :tournament_results, proc { |*args|
            params = args.last.is_a?(Hash) ? args.last : {}
            params[:format] == :html ? @html : @json_obj
          } do
            scoreboard = GolfGenius::Scoreboard.new(event: "1002", round: "2001")
            tournament = scoreboard.tournaments.first
            rows = tournament.rows

            # Player X (position: 1)
            player_x = rows[0]

            assert_equal "1", player_x.position
            assert_predicate player_x, :competing?
            refute_predicate player_x, :eliminated?
            refute_predicate player_x, :cut?

            # Player Y (position: 2)
            player_y = rows[1]

            assert_equal "2", player_y.position
            assert_predicate player_y, :competing?
            refute_predicate player_y, :eliminated?
            refute_predicate player_y, :cut?

            # Player Z (position: CUT)
            player_z = rows[2]

            assert_equal "CUT", player_z.position
            refute_predicate player_z, :competing?
            assert_predicate player_z, :eliminated?
            assert_predicate player_z, :cut?
          end
        end
      end
    end
  end

  private

  def create_row_with_position(position_value)
    tournament_data = {
      meta: {
        tournament_id: 1,
        name: "Test",
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
      rows: [
        {
          id: 1,
          name: "Test Player",
          player_ids: ["123"],
          affiliation: "Test Club",
          tournament_id: 1,
          summary: {
            position: position_value,
            player: "Test Player",
          },
          rounds: {},
        },
      ],
    }

    tournament = GolfGenius::Scoreboard::Tournament.new(tournament_data)
    tournament.rows.first
  end

  def create_row_without_position
    tournament_data = {
      meta: {
        tournament_id: 1,
        name: "Test",
        cut_text: nil,
        adjusted: false,
        rounds: [],
      },
      columns: {
        summary: [
          { key: :player, format: "player", label: "Player", index: 0 },
        ],
        rounds: [],
      },
      rows: [
        {
          id: 1,
          name: "Test Player",
          player_ids: ["123"],
          affiliation: "Test Club",
          tournament_id: 1,
          summary: {
            player: "Test Player",
          },
          rounds: {},
        },
      ],
    }

    tournament = GolfGenius::Scoreboard::Tournament.new(tournament_data)
    tournament.rows.first
  end
end
