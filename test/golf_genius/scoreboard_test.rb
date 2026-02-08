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

  def create_mock_event(id, name)
    event = Object.new
    event.define_singleton_method(:id) { id }
    event.define_singleton_method(:[]) do |key|
      [:name, "name"].include?(key) ? name : nil
    end
    event
  end

  def create_mock_round(id, name, index, date)
    round = Object.new
    round.define_singleton_method(:id) { id }
    round.define_singleton_method(:[]) do |key|
      case key
      when :id, "id" then id
      when :name, "name" then name
      when :index, "index" then index
      when :date, "date" then date
      end
    end
    round
  end

  def create_mock_tournament(id, name)
    tournament = Object.new
    tournament.define_singleton_method(:id) { id }
    tournament.define_singleton_method(:[]) { |key| key == :name ? name : nil }
    tournament.define_singleton_method(:non_scoring?) { false }
    tournament
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

  def test_skip_event_fetch_avoids_expensive_event_fetch
    # Test that skip_event_fetch: true doesn't call Event.fetch
    round = create_mock_round("1615931", "R1", 1, "2026-03-15")
    tournament = create_mock_tournament("4522280", "Overall Results")

    event_fetch_called = false
    event_fetch_stub = lambda do |*_args|
      event_fetch_called = true
      raise "Event.fetch should not be called when skip_event_fetch: true"
    end

    GolfGenius::Event.stub :fetch, event_fetch_stub do
      GolfGenius::Event.stub :rounds, [round] do
        GolfGenius::Event.stub :tournaments, [tournament] do
          GolfGenius::Event.stub :tournament_results, stub_tournament_results_lambda do
            scoreboard = GolfGenius::Scoreboard.new(
              event: "522157",
              round: "1615931",
              skip_event_fetch: true
            )
            schema = scoreboard.to_h

            refute event_fetch_called, "Event.fetch should not be called with skip_event_fetch: true"
            assert_equal "522157", schema[:meta][:event_name], "Should use event_id as event_name fallback"
          end
        end
      end
    end
  end

  def test_skip_event_fetch_builds_valid_schema
    # Test that schema is valid even without event metadata
    round = create_mock_round("1615931", "R1", 1, "2026-03-15")
    tournament = create_mock_tournament("4522280", "Overall Results")

    GolfGenius::Event.stub :rounds, [round] do
      GolfGenius::Event.stub :tournaments, [tournament] do
        GolfGenius::Event.stub :tournament_results, stub_tournament_results_lambda do
          scoreboard = GolfGenius::Scoreboard.new(
            event: "522157",
            round: "1615931",
            skip_event_fetch: true
          )
          schema = scoreboard.to_h

          assert_equal "522157", schema[:meta][:event_id]
          assert_equal "522157", schema[:meta][:event_name]
          assert_equal "1615931", schema[:meta][:round_id]
          assert_equal "R1", schema[:meta][:round_name]
          assert_equal 1, schema[:tournaments].size
        end
      end
    end
  end

  def test_event_object_memoizes_when_passed
    # Test that passing an event object memoizes it and avoids fetching
    event = create_mock_event("522157", "Test Event")
    round = create_mock_round("1615931", "R1", 1, "2026-03-15")
    tournament = create_mock_tournament("4522280", "Overall Results")

    event_fetch_called = false
    event_fetch_stub = lambda do |*_args|
      event_fetch_called = true
      raise "Event.fetch should not be called when event object is passed"
    end

    GolfGenius::Event.stub :fetch, event_fetch_stub do
      GolfGenius::Event.stub :rounds, [round] do
        GolfGenius::Event.stub :tournaments, [tournament] do
          GolfGenius::Event.stub :tournament_results, stub_tournament_results_lambda do
            scoreboard = GolfGenius::Scoreboard.new(
              event: event,
              round: "1615931"
            )
            schema = scoreboard.to_h

            refute event_fetch_called, "Event.fetch should not be called when event object is passed"
            assert_equal "Test Event", schema[:meta][:event_name]
          end
        end
      end
    end
  end

  def test_event_name_uses_event_object_when_available
    # Test that event name comes from event object when not skipped
    event = create_mock_event("522157", "My Tournament Event")
    round = create_mock_round("1615931", "R1", 1, "2026-03-15")
    tournament = create_mock_tournament("4522280", "Overall Results")

    GolfGenius::Event.stub :fetch, event do
      GolfGenius::Event.stub :rounds, [round] do
        GolfGenius::Event.stub :tournaments, [tournament] do
          GolfGenius::Event.stub :tournament_results, stub_tournament_results_lambda do
            scoreboard = GolfGenius::Scoreboard.new(
              event: "522157",
              round: "1615931"
            )
            schema = scoreboard.to_h

            assert_equal "My Tournament Event", schema[:meta][:event_name]
          end
        end
      end
    end
  end

  def test_sort_reuses_schema_without_rebuilding
    # CRITICAL: This tests the main performance fix
    # Before the fix, sort() would pass a schema but to_h would ignore it
    # and rebuild everything from scratch, re-fetching all data!
    event = create_mock_event("522157", "Test Event")
    round = create_mock_round("1615931", "R1", 1, "2026-03-15")
    tournament = create_mock_tournament("4522280", "Overall Results")

    fetch_count = 0
    rounds_count = 0
    tournaments_count = 0
    results_count = 0

    fetch_stub = lambda do |*_args|
      fetch_count += 1
      event
    end

    rounds_stub = lambda do |*_args|
      rounds_count += 1
      [round]
    end

    tournaments_stub = lambda do |*_args|
      tournaments_count += 1
      [tournament]
    end

    results_stub = lambda do |*args|
      results_count += 1
      stub_tournament_results_lambda.call(*args)
    end

    GolfGenius::Event.stub :fetch, fetch_stub do
      GolfGenius::Event.stub :rounds, rounds_stub do
        GolfGenius::Event.stub :tournaments, tournaments_stub do
          GolfGenius::Event.stub :tournament_results, results_stub do
            # Create initial scoreboard - this should build schema once
            scoreboard = GolfGenius::Scoreboard.new(event: "522157", round: "1615931")
            original_schema = scoreboard.to_h

            # Capture call counts after initial build
            initial_fetch = fetch_count
            initial_rounds = rounds_count
            initial_tournaments = tournaments_count
            initial_results = results_count

            # Sort the scoreboard - this creates a new Scoreboard with schema parameter
            sorted = scoreboard.sort(:position)
            sorted_schema = sorted.to_h

            # CRITICAL ASSERTION: Sorting should NOT trigger any additional API calls
            # because the schema parameter should be reused
            assert_equal initial_fetch, fetch_count,
                         "sort() should not call Event.fetch again (schema should be reused)"
            assert_equal initial_rounds, rounds_count,
                         "sort() should not call Event.rounds again (schema should be reused)"
            assert_equal initial_tournaments, tournaments_count,
                         "sort() should not call Event.tournaments again (schema should be reused)"
            assert_equal initial_results, results_count,
                         "sort() should not call tournament_results again (schema should be reused)"

            # Verify schemas are different objects but have same structure
            refute_same original_schema, sorted_schema, "Sorted schema should be a different object"
            assert_equal original_schema[:meta], sorted_schema[:meta], "Metadata should be identical"
          end
        end
      end
    end
  end

  def test_schema_parameter_is_respected
    # Test that when a schema is passed to new(), it's used instead of building
    pre_built_schema = {
      meta: {
        event_id: "522157",
        event_name: "Test Event",
        round_id: "1615931",
        round_name: "R1",
      },
      tournaments: [],
    }

    # These should never be called because schema is provided
    fetch_stub = ->(*_args) { raise "Event.fetch should not be called when schema is provided" }
    rounds_stub = ->(*_args) { raise "Event.rounds should not be called when schema is provided" }
    tournaments_stub = ->(*_args) { raise "Event.tournaments should not be called when schema is provided" }

    GolfGenius::Event.stub :fetch, fetch_stub do
      GolfGenius::Event.stub :rounds, rounds_stub do
        GolfGenius::Event.stub :tournaments, tournaments_stub do
          scoreboard = GolfGenius::Scoreboard.new(
            event: "522157",
            round: "1615931",
            schema: pre_built_schema
          )

          result = scoreboard.to_h

          # Should return the exact schema that was passed in
          assert_equal pre_built_schema, result
        end
      end
    end
  end

  def test_resolves_latest_round_by_index
    # Mock event
    event = Object.new
    def event.id = "522157"

    def event.[](key)
      [:name, "name"].include?(key) ? "Test Event" : nil
    end

    # Mock rounds for metadata with proper index/date for latest_round logic
    round = Object.new
    def round.id = "1615932"

    def round.[](key)
      case key
      when :id, "id" then "1615932"
      when :name, "name" then "R1"
      when :index, "index" then 1
      when :date, "date" then "2026-03-15"
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

    GolfGenius::Event.stub :fetch, event do
      GolfGenius::Event.stub :rounds, [] do
        scoreboard = GolfGenius::Scoreboard.new(event: "522157")

        error = assert_raises(StandardError) do
          scoreboard.to_h
        end

        assert_match(/No rounds found for event/, error.message)
      end
    end
  end

  def test_resolves_latest_round_from_multiple_rounds
    # Test that latest round is selected correctly by index (primary) and date (fallback)
    event = create_mock_event("522157", "Test Event")
    round1 = create_mock_round("1615930", "R1", 1, "2026-03-15")
    round2 = create_mock_round("1615931", "R2", 2, "2026-03-16")
    round3 = create_mock_round("1615932", "R3", 3, "2026-03-17")
    tournament = create_mock_tournament("4522280", "Overall Results")

    # Verify rounds is only called once (memoization)
    rounds_call_count = 0
    rounds_stub = lambda do |*_args|
      rounds_call_count += 1
      [round1, round2, round3]
    end

    GolfGenius::Event.stub :fetch, event do
      GolfGenius::Event.stub :rounds, rounds_stub do
        GolfGenius::Event.stub :tournaments, [tournament] do
          GolfGenius::Event.stub :tournament_results, stub_tournament_results_lambda do
            scoreboard = GolfGenius::Scoreboard.new(event: "522157")
            schema = scoreboard.to_h

            # Should resolve to R3 (highest index)
            assert_equal "1615932", schema[:meta][:round_id]
            assert_equal "R3", schema[:meta][:round_name]

            # Verify memoization: rounds should only be called once
            assert_equal 1, rounds_call_count, "Expected rounds to be called once (memoization), but was called #{rounds_call_count} times"
          end
        end
      end
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
