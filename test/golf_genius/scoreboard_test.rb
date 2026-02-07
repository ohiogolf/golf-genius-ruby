# frozen_string_literal: true

require "test_helper"

class ScoreboardTest < Minitest::Test
  def test_initialize_with_event_id_string
    scoreboard = GolfGenius::Scoreboard.new(event: "522157")

    assert_equal "522157", scoreboard.event_id
  end

  def test_initialize_with_event_object
    event = Object.new
    def event.id
      "522157"
    end

    scoreboard = GolfGenius::Scoreboard.new(event: event)

    assert_equal "522157", scoreboard.event_id
  end

  def test_initialize_with_round_id_string
    scoreboard = GolfGenius::Scoreboard.new(event: "522157", round: "1615931")

    assert_equal "1615931", scoreboard.round_id
  end

  def test_initialize_with_round_object
    round = Object.new
    def round.id
      "1615931"
    end

    scoreboard = GolfGenius::Scoreboard.new(event: "522157", round: round)

    assert_equal "1615931", scoreboard.round_id
  end

  def test_initialize_with_tournament_id_string
    scoreboard = GolfGenius::Scoreboard.new(event: "522157", tournament: "4522280")

    assert_equal "4522280", scoreboard.tournament_id
  end

  def test_initialize_with_tournament_object
    tournament = Object.new
    def tournament.id
      "4522280"
    end

    scoreboard = GolfGenius::Scoreboard.new(event: "522157", tournament: tournament)

    assert_equal "4522280", scoreboard.tournament_id
  end

  def test_initialize_without_event_raises_error
    # Ruby 3.x raises ArgumentError with "missing keyword: :event"
    assert_raises(ArgumentError) do
      GolfGenius::Scoreboard.new
    end
  end

  def test_to_h_returns_schema_structure
    # Mock event, round, and tournament
    event, round, tournament = setup_mocks

    GolfGenius::Event.stub :fetch, event do
      GolfGenius::Event.stub :rounds, [round] do
        GolfGenius::Event.stub :tournaments, [tournament] do
          GolfGenius::Event.stub :tournament_results, stub_tournament_results_lambda do
            scoreboard = GolfGenius::Scoreboard.new(event: "522157", round: "1615931")
            schema = scoreboard.to_h

            assert_kind_of Hash, schema
            assert schema.key?(:meta)
            assert schema.key?(:tournaments)
            assert_equal "522157", schema[:meta][:event_id]
            assert_kind_of Array, schema[:tournaments]
          end
        end
      end
    end
  end

  private

  def setup_mocks
    event = Object.new
    def event.id = "522157"

    def event.[](key)
      [:name, "name"].include?(key) ? "Test Event" : nil
    end

    round = Object.new
    def round.id = "1615931"

    def round.[](key)
      case key
      when :id, "id" then "1615931"
      when :name, "name" then "R1"
      end
    end

    tournament = Object.new
    def tournament.id = "4522280"

    def tournament.[](key)
      key == :name ? "Overall Results" : nil
    end

    def tournament.non_scoring? = false

    [event, round, tournament]
  end

  def stub_tournament_results_lambda
    lambda do |*args|
      params = args.last.is_a?(Hash) ? args.last : {}
      if params[:format] == :html
        "<table><tr class='header thead'></tr></table>"
      else
        json_obj = Object.new
        # rubocop:disable Lint/UnusedMethodArgument
        def json_obj.to_json(raw: true)
          '{"name":"Overall Results","adjusted":false,"rounds":[],"scopes":[]}'
        end
        # rubocop:enable Lint/UnusedMethodArgument
        json_obj
      end
    end
  end

  public

  def test_to_h_memoizes_result
    event, round, tournament = setup_mocks

    GolfGenius::Event.stub :fetch, event do
      GolfGenius::Event.stub :rounds, [round] do
        GolfGenius::Event.stub :tournaments, [tournament] do
          GolfGenius::Event.stub :tournament_results, stub_tournament_results_lambda do
            scoreboard = GolfGenius::Scoreboard.new(event: "522157", round: "1615931")
            first_call = scoreboard.to_h
            second_call = scoreboard.to_h

            assert_same first_call, second_call
          end
        end
      end
    end
  end

  def test_resolves_latest_round_by_index
    # Mock event with latest_round method
    event = Object.new
    def event.id = "522157"

    def event.[](key)
      [:name, "name"].include?(key) ? "Test Event" : nil
    end

    def event.latest_round(_params = {})
      latest_round = Object.new
      def latest_round.id = "1615932"
      latest_round
    end

    # Mock rounds for metadata
    round = Object.new
    def round.id = "1615932"

    def round.[](key)
      case key
      when :id, "id" then "1615932"
      when :name, "name" then "R1"
      end
    end

    # Mock tournament
    tournament = Object.new
    def tournament.id = "4522280"

    def tournament.[](key)
      key == :name ? "Overall Results" : nil
    end

    def tournament.non_scoring? = false

    GolfGenius::Event.stub :fetch, event do
      GolfGenius::Event.stub :rounds, [round] do
        GolfGenius::Event.stub :tournaments, [tournament] do
          GolfGenius::Event.stub :tournament_results, stub_tournament_results_lambda do
            scoreboard = GolfGenius::Scoreboard.new(event: "522157")
            schema = scoreboard.to_h

            assert_equal "1615932", schema[:meta][:round_id]
          end
        end
      end
    end
  end

  def test_uses_explicit_round_id_when_provided
    event = Object.new
    def event.id = "522157"

    def event.[](key)
      [:name, "name"].include?(key) ? "Test Event" : nil
    end

    # Create round with matching ID
    round = Object.new
    def round.id = "1615930"

    def round.[](key)
      case key
      when :id, "id" then "1615930"
      when :name, "name" then "R1"
      end
    end

    tournament = Object.new
    def tournament.id = "4522280"

    def tournament.[](key)
      key == :name ? "Overall Results" : nil
    end

    def tournament.non_scoring? = false

    GolfGenius::Event.stub :fetch, event do
      GolfGenius::Event.stub :rounds, [round] do
        GolfGenius::Event.stub :tournaments, [tournament] do
          GolfGenius::Event.stub :tournament_results, stub_tournament_results_lambda do
            scoreboard = GolfGenius::Scoreboard.new(event: "522157", round: "1615930")
            schema = scoreboard.to_h

            # Should use explicit round_id, not resolve to latest
            assert_equal "1615930", schema[:meta][:round_id]
          end
        end
      end
    end
  end

  def test_raises_error_when_no_rounds_exist
    event = Object.new
    def event.id = "522157"

    def event.latest_round(_params = {})
      nil
    end

    GolfGenius::Event.stub :fetch, event do
      scoreboard = GolfGenius::Scoreboard.new(event: "522157")

      error = assert_raises(StandardError) do
        scoreboard.to_h
      end

      assert_match(/No rounds found for event/, error.message)
    end
  end

  def test_resolves_all_scoring_tournaments
    event, round, = setup_mocks

    tournament1 = Object.new
    def tournament1.id = "4522280"

    def tournament1.[](key)
      key == :name ? "Overall Results" : nil
    end

    def tournament1.non_scoring? = false

    tournament2 = Object.new
    def tournament2.id = "4522284"

    def tournament2.[](key)
      key == :name ? "16-18 Results" : nil
    end

    def tournament2.non_scoring? = false

    tournament3 = Object.new
    def tournament3.id = "4522288"

    def tournament3.[](key)
      key == :name ? "15 & Under Results" : nil
    end

    def tournament3.non_scoring? = false

    GolfGenius::Event.stub :fetch, event do
      GolfGenius::Event.stub :rounds, [round] do
        GolfGenius::Event.stub :tournaments, [tournament1, tournament2, tournament3] do
          GolfGenius::Event.stub :tournament_results, stub_tournament_results_lambda do
            scoreboard = GolfGenius::Scoreboard.new(event: "522157", round: "1615931")
            scoreboard.to_h

            # Should store all tournament IDs
            assert_equal %w[4522280 4522284 4522288], scoreboard.instance_variable_get(:@tournament_ids)
          end
        end
      end
    end
  end

  def test_filters_out_non_scoring_tournaments
    event, round, = setup_mocks

    tournament1 = Object.new
    def tournament1.id = "4522280"

    def tournament1.[](key)
      key == :name ? "Overall Results" : nil
    end

    def tournament1.non_scoring? = false

    tournament2 = Object.new
    def tournament2.id = "9999"

    def tournament2.[](key)
      key == :name ? "Pairings Sheet" : nil
    end

    def tournament2.non_scoring? = true

    tournament3 = Object.new
    def tournament3.id = "9998"

    def tournament3.[](key)
      key == :name ? "Scorecard Printing" : nil
    end

    def tournament3.non_scoring? = true

    GolfGenius::Event.stub :fetch, event do
      GolfGenius::Event.stub :rounds, [round] do
        GolfGenius::Event.stub :tournaments, [tournament1, tournament2, tournament3] do
          GolfGenius::Event.stub :tournament_results, stub_tournament_results_lambda do
            scoreboard = GolfGenius::Scoreboard.new(event: "522157", round: "1615931")
            scoreboard.to_h

            # Should only include scoring tournament
            assert_equal ["4522280"], scoreboard.instance_variable_get(:@tournament_ids)
          end
        end
      end
    end
  end

  def test_uses_explicit_tournament_id_when_provided
    event, round, = setup_mocks

    tournament1 = Object.new
    def tournament1.id = "4522280"

    def tournament1.[](key)
      key == :name ? "Overall Results" : nil
    end

    def tournament1.non_scoring? = false

    tournament2 = Object.new
    def tournament2.id = "4522284"

    def tournament2.[](key)
      key == :name ? "16-18 Results" : nil
    end

    def tournament2.non_scoring? = false

    GolfGenius::Event.stub :fetch, event do
      GolfGenius::Event.stub :rounds, [round] do
        GolfGenius::Event.stub :tournaments, [tournament1, tournament2] do
          GolfGenius::Event.stub :tournament_results, stub_tournament_results_lambda do
            scoreboard = GolfGenius::Scoreboard.new(event: "522157", round: "1615931", tournament: "4522280")
            scoreboard.to_h

            # Should only include specified tournament
            assert_equal ["4522280"], scoreboard.instance_variable_get(:@tournament_ids)
          end
        end
      end
    end
  end

  def test_raises_error_when_no_tournaments_exist
    GolfGenius::Event.stub :tournaments, [] do
      scoreboard = GolfGenius::Scoreboard.new(event: "522157", round: "1615931")

      error = assert_raises(StandardError) do
        scoreboard.to_h
      end

      assert_match(/No tournaments found/, error.message)
    end
  end

  def test_raises_error_when_no_scoring_tournaments_exist
    tournament1 = Object.new
    def tournament1.id = "9999"

    def tournament1.[](key)
      key == :name ? "Pairings Only" : nil
    end

    def tournament1.non_scoring? = true

    GolfGenius::Event.stub :tournaments, [tournament1] do
      scoreboard = GolfGenius::Scoreboard.new(event: "522157", round: "1615931")

      error = assert_raises(StandardError) do
        scoreboard.to_h
      end

      assert_match(/No scoring tournaments found/, error.message)
    end
  end

  def test_tournaments_accessor_returns_tournaments_array
    event, round, tournament = setup_mocks

    GolfGenius::Event.stub :fetch, event do
      GolfGenius::Event.stub :rounds, [round] do
        GolfGenius::Event.stub :tournaments, [tournament] do
          GolfGenius::Event.stub :tournament_results, stub_tournament_results_lambda do
            scoreboard = GolfGenius::Scoreboard.new(event: "522157", round: "1615931")

            assert_kind_of Array, scoreboard.tournaments
            assert_equal 1, scoreboard.tournaments.length
          end
        end
      end
    end
  end

  def test_tournament_accessor_finds_by_id
    event, round, tournament = setup_mocks

    GolfGenius::Event.stub :fetch, event do
      GolfGenius::Event.stub :rounds, [round] do
        GolfGenius::Event.stub :tournaments, [tournament] do
          GolfGenius::Event.stub :tournament_results, stub_tournament_results_lambda do
            scoreboard = GolfGenius::Scoreboard.new(event: "522157", round: "1615931")

            result = scoreboard.tournament(4_522_280)

            assert_equal "Overall Results", result.name
          end
        end
      end
    end
  end

  def test_tournament_accessor_finds_by_name
    event, round, tournament = setup_mocks

    GolfGenius::Event.stub :fetch, event do
      GolfGenius::Event.stub :rounds, [round] do
        GolfGenius::Event.stub :tournaments, [tournament] do
          GolfGenius::Event.stub :tournament_results, stub_tournament_results_lambda do
            scoreboard = GolfGenius::Scoreboard.new(event: "522157", round: "1615931")

            result = scoreboard.tournament("Overall Results")

            assert_equal 4_522_280, result.tournament_id
          end
        end
      end
    end
  end

  def test_tournament_accessor_finds_by_partial_name
    event, round, tournament = setup_mocks

    GolfGenius::Event.stub :fetch, event do
      GolfGenius::Event.stub :rounds, [round] do
        GolfGenius::Event.stub :tournaments, [tournament] do
          GolfGenius::Event.stub :tournament_results, stub_tournament_results_lambda do
            scoreboard = GolfGenius::Scoreboard.new(event: "522157", round: "1615931")

            result = scoreboard.tournament("overall")

            assert_equal 4_522_280, result.tournament_id
          end
        end
      end
    end
  end

  def test_rows_accessor_returns_all_rows_with_tournament_id
    event, round, tournament = setup_mocks

    GolfGenius::Event.stub :fetch, event do
      GolfGenius::Event.stub :rounds, [round] do
        GolfGenius::Event.stub :tournaments, [tournament] do
          GolfGenius::Event.stub :tournament_results, stub_tournament_results_lambda do
            scoreboard = GolfGenius::Scoreboard.new(event: "522157", round: "1615931")

            all_rows = scoreboard.rows

            assert_kind_of Array, all_rows

            # Each row should have tournament_id
            all_rows.each do |row|
              assert row.key?(:tournament_id)
            end
          end
        end
      end
    end
  end

  def test_full_integration_with_fixtures
    # Load fixtures
    html = File.read(File.join(__dir__, "../fixtures/tournament_results/multi_round_stroke_play.html"))
    File.read(File.join(__dir__, "../fixtures/tournament_results/multi_round_stroke_play.json"))

    # Create mock objects
    event = Object.new
    def event.id = "1000"

    def event.[](key)
      [:name, "name"].include?(key) ? "Test Event" : nil
    end

    round = Object.new
    def round.id = 2001

    def round.[](key)
      case key
      when :id, "id" then 2001
      when :name, "name" then "R2"
      end
    end

    tournament = Object.new
    def tournament.id = "1001"

    def tournament.[](key)
      key == :name ? "Test Tournament" : nil
    end

    def tournament.non_scoring? = false

    json_obj = Object.new
    # rubocop:disable Lint/UnusedMethodArgument
    def json_obj.to_json(raw: true)
      File.read(File.join(__dir__, "../fixtures/tournament_results/multi_round_stroke_play.json"))
    end
    # rubocop:enable Lint/UnusedMethodArgument

    # Stub API calls
    GolfGenius::Event.stub :fetch, event do
      GolfGenius::Event.stub :rounds, [round] do
        GolfGenius::Event.stub :tournaments, [tournament] do
          GolfGenius::Event.stub :tournament_results, proc { |*args|
            params = args.last.is_a?(Hash) ? args.last : {}
            params[:format] == :html ? html : json_obj
          } do
            scoreboard = GolfGenius::Scoreboard.new(event: "1000", round: "2001")
            result = scoreboard.to_h

            # Verify top-level structure
            assert result.key?(:meta)
            assert result.key?(:tournaments)

            # Verify meta
            assert_equal "1000", result[:meta][:event_id]
            assert_equal "Test Event", result[:meta][:event_name]
            assert_equal "2001", result[:meta][:round_id]
            assert_equal "R2", result[:meta][:round_name]

            # Verify tournaments
            assert_equal 1, result[:tournaments].length

            tournament = result[:tournaments][0]

            assert tournament.key?(:meta)
            assert tournament.key?(:columns)
            assert tournament.key?(:rows)

            # Verify tournament meta
            assert_equal "Test Tournament", tournament[:meta][:name]
            assert_equal false, tournament[:meta][:adjusted]

            # Verify columns structure
            assert tournament[:columns].key?(:summary)
            assert tournament[:columns].key?(:rounds)

            # Verify rows
            assert_equal 3, tournament[:rows].length

            # Check first row structure
            row = tournament[:rows][0]

            assert_equal 1001, row[:id]
            assert_equal "Player A", row[:name]
            assert row.key?(:summary)
            assert row.key?(:rounds)

            # Verify summary cells
            assert row[:summary].key?(:position)
            assert row[:summary].key?(:player)

            # Verify round data with scorecard
            assert row[:rounds].key?(2001)
            assert row[:rounds][2001].key?(:scorecard)
          end
        end
      end
    end
  end
end
