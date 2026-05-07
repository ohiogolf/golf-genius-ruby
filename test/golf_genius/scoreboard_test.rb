# frozen_string_literal: true

require "test_helper"

class ScoreboardTest < Minitest::Test
  def test_initialize_with_event_id_string
    scoreboard = GolfGenius::Scoreboard.new(event: "522157")

    assert_equal "522157", scoreboard.event_id
  end

  def test_initialize_with_event_object
    event = Object.new
    def event.id = "522157"

    scoreboard = GolfGenius::Scoreboard.new(event: event)

    assert_equal "522157", scoreboard.event_id
  end

  def test_initialize_with_round_and_tournament_ids
    scoreboard = GolfGenius::Scoreboard.new(event: "522157", round: "1615931", tournament: "4522280")

    assert_equal "1615931", scoreboard.round_id
    assert_equal "4522280", scoreboard.tournament_id
  end

  def test_initialize_without_event_raises_error
    assert_raises(ArgumentError) do
      GolfGenius::Scoreboard.new
    end
  end

  def test_to_h_returns_normalized_structure
    event, round, tournament = setup_mocks
    roster = [
      GolfGenius::RosterMember.construct_from(
        {
          "id" => "101",
          "name" => "Jane Doe",
          "first_name" => "Jane",
          "last_name" => "Doe",
          "member_card_id" => "555",
          "custom_fields" => {
            "affiliation" => "Test CC",
            "city" => "Columbus",
            "state" => "OH",
          },
        }
      ),
    ]
    tee_sheet = [
      GolfGenius::TeeSheetGroup.construct_from(
        {
          "tee_time" => "8:30 AM",
          "players" => [
            {
              "name" => "Jane Doe",
              "player_roster_id" => "101",
              "member_card_id" => "555",
              "score_array" => [4, 4, 3, 4, 5, 4, 3, 4] + Array.new(10),
              "tee" => {
                "name" => "Blue",
                "abbreviation" => "BLU",
                "color" => "#00f",
              },
            },
          ],
        }
      ),
    ]
    json_payload = {
      "name" => "Overall Results",
      "adjusted" => false,
      "column_names" => {
        "score" => "To Par<br/>Gross",
        "affiliation" => "city%2C state or country",
      },
      "column_visibility" => {
        "score" => true,
        "affiliation" => true,
      },
      "rounds" => [
        {
          "id" => 1_615_931,
          "name" => "Round 1",
          "date" => "2026-03-15",
          "in_progress" => true,
        },
      ],
      "scopes" => [
        {
          "aggregates" => [
            {
              "id" => 99,
              "name" => "Jane   Doe (a)",
              "position" => "1",
              "affiliation" => "Test CC",
              "details" => "",
              "disposition" => "",
              "disposition_cause" => "",
              "rank" => "1",
              "member_ids" => ["101"],
              "member_cards" => [
                {
                  "member_id" => 101,
                  "member_card_id" => 555,
                },
              ],
              "thru" => "8",
              "score" => "-2",
              "gross_scores" => [4, 4, 3, 4, 5, 4, 3, 4] + Array.new(10),
              "net_scores" => [],
              "to_par_gross" => [],
              "to_par_net" => [],
              "totals" => {
                "gross_scores" => {
                  "out" => 35,
                  "in" => nil,
                  "total" => nil,
                },
              },
              "scorecard_statuses" => [
                {
                  "member_card_id" => 555,
                  "status" => "partial",
                },
              ],
            },
          ],
        },
      ],
    }

    scoreboard = build_scoreboard(
      event: event,
      rounds: [round],
      tournaments: [tournament],
      sources: { roster: roster, tee_sheet: tee_sheet },
      json_payload: json_payload
    )

    schema = scoreboard.to_h

    assert_equal "522157", schema[:meta][:event_id]
    assert_equal "1615931", schema[:meta][:selected_round][:id]
    assert_equal "1615931", schema[:meta][:current_round][:id]
    assert_equal "R1", schema[:rounds].first[:name]

    tournament_data = schema[:tournaments].first
    entry = tournament_data[:entries].first
    round_data = entry[:rounds]["1615931"]

    assert_equal "4522280", tournament_data[:id]
    assert_equal "Overall Results", tournament_data[:name]
    assert_equal "To Par Gross", tournament_data[:columns]["score"][:label]
    assert_equal "99", entry[:id]
    assert_equal "1", entry[:position]
    assert_equal 1, entry[:rank]
    assert_equal "playing", entry[:state]
    assert_equal "Jane Doe (a)", entry[:players].first[:name][:full]
    assert_equal true, entry[:players].first[:name][:amateur]
    assert_equal "Columbus", entry[:players].first[:location][:city]
    assert_equal "Blue", entry[:players].first[:tee][:name]
    assert_equal "8:30 AM", round_data[:tee_time]
    assert_equal "playing", round_data[:state]
    assert_equal(-2, round_data[:to_par_total])
  end

  def test_to_h_derives_partial_stroke_totals_from_live_hole_scores
    event = create_mock_event("fixture-event", "Fixture Event")
    round1 = create_mock_round("2000", "R1", 1, "2026-03-15", status: "completed")
    round2 = create_mock_round("2001", "R2", 2, "2026-03-16", status: "in progress")
    tournament = create_mock_tournament("5001", "Test Tournament")
    json_payload = JSON.parse(
      File.read(File.expand_path("../fixtures/tournament_results/multi_round_stroke_play.json", __dir__))
    )

    scoreboard = build_scoreboard(
      event: event,
      rounds: [round1, round2],
      tournaments: [tournament],
      json_payload: json_payload
    )

    entries = scoreboard.to_h[:tournaments].first[:entries]
    player_a = entries.find { |entry| entry[:name] == "Player A" }
    player_b = entries.find { |entry| entry[:name] == "Player B" }

    assert_equal({ out: 24, in: nil, total: 24 }, player_a[:rounds]["2001"][:stroke_totals])
    assert_equal({ out: 36, in: nil, total: 36 }, player_b[:rounds]["2001"][:stroke_totals])
  end

  def test_to_h_ignores_non_numeric_stroke_total_markers
    event = create_mock_event("fixture-event", "Fixture Event")
    round1 = create_mock_round("2000", "R1", 1, "2026-03-15", status: "completed")
    tournament = create_mock_tournament("5001", "Test Tournament")
    json_payload = {
      "name" => "Overall Results",
      "adjusted" => false,
      "rounds" => [
        { "id" => 2000, "name" => "Round 1", "date" => "2026-03-15", "in_progress" => false },
      ],
      "scopes" => [
        {
          "aggregates" => [
            {
              "id" => 99,
              "name" => "Player A",
              "position" => "WD",
              "disposition" => "WD",
              "disposition_cause" => "",
              "member_ids" => ["101"],
              "member_cards" => [],
              "thru" => "9",
              "score" => nil,
              "gross_scores" => [4, 4, 4, 4, 4, 4, 4, 4, 4] + Array.new(9),
              "net_scores" => [],
              "to_par_gross" => [],
              "to_par_net" => [],
              "totals" => {
                "gross_scores" => {
                  "out" => 36,
                  "in" => nil,
                  "total" => "WD",
                },
              },
              "scorecard_statuses" => [
                {
                  "status" => "partial",
                },
              ],
            },
          ],
        },
      ],
    }

    scoreboard = build_scoreboard(
      event: event,
      rounds: [round1],
      tournaments: [tournament],
      json_payload: json_payload
    )

    entry = scoreboard.to_h[:tournaments].first[:entries].first

    assert_equal "wd", entry[:outcome]
    assert_equal({ out: 36, in: nil, total: 36 }, entry[:rounds]["2000"][:stroke_totals])
  end

  def test_to_h_uses_tee_sheet_when_json_has_no_round_section
    event, round, tournament = setup_mocks
    roster = [
      GolfGenius::RosterMember.construct_from(
        {
          "id" => "101",
          "name" => "Jane Doe",
          "member_card_id" => "555",
          "custom_fields" => {},
        }
      ),
    ]
    tee_sheet = [
      GolfGenius::TeeSheetGroup.construct_from(
        {
          "tee_time" => "8:30 AM",
          "players" => [
            {
              "name" => "Jane Doe",
              "player_roster_id" => "101",
              "member_card_id" => "555",
              "score_array" => [],
            },
          ],
        }
      ),
    ]
    json_payload = {
      "name" => "Overall Results",
      "adjusted" => false,
      "rounds" => [],
      "scopes" => [
        {
          "aggregates" => [
            {
              "id" => 99,
              "name" => "Jane Doe",
              "member_ids" => ["101"],
              "member_cards" => [{ "member_id" => 101, "member_card_id" => 555 }],
              "gross_scores" => Array.new(18),
              "net_scores" => [],
              "to_par_gross" => [],
              "to_par_net" => [],
              "totals" => { "gross_scores" => { "out" => nil, "in" => nil, "total" => nil } },
              "scorecard_statuses" => [{ "member_card_id" => 555, "status" => "no_holes" }],
            },
          ],
        },
      ],
    }

    scoreboard = build_scoreboard(
      event: event,
      rounds: [round],
      tournaments: [tournament],
      sources: { roster: roster, tee_sheet: tee_sheet },
      json_payload: json_payload
    )

    round_data = scoreboard.to_h[:tournaments].first[:entries].first[:rounds]["1615931"]

    assert_equal "8:30 AM", round_data[:tee_time]
    assert_equal "not_started", round_data[:state]
  end

  def test_to_h_uses_member_card_lookup_for_round_tee_data
    event, round, tournament = setup_mocks
    roster = [
      GolfGenius::RosterMember.construct_from(
        {
          "id" => "101",
          "name" => "Jane Doe",
          "member_card_id" => "555",
          "custom_fields" => {},
        }
      ),
    ]
    tee_sheet = [
      GolfGenius::TeeSheetGroup.construct_from(
        {
          "tee_time" => "9:10 AM",
          "players" => [
            {
              "name" => "Jane Doe",
              "member_card_id" => "555",
              "score_array" => [],
            },
          ],
        }
      ),
    ]
    json_payload = {
      "name" => "Overall Results",
      "adjusted" => false,
      "rounds" => [],
      "scopes" => [
        {
          "aggregates" => [
            {
              "id" => 99,
              "name" => "Jane Doe",
              "member_ids" => ["101"],
              "member_cards" => [{ "member_id" => 101, "member_card_id" => 555 }],
              "gross_scores" => Array.new(18),
              "net_scores" => [],
              "to_par_gross" => [],
              "to_par_net" => [],
              "totals" => { "gross_scores" => { "out" => nil, "in" => nil, "total" => nil } },
              "scorecard_statuses" => [{ "member_card_id" => 555, "status" => "no_holes" }],
            },
          ],
        },
      ],
    }

    scoreboard = build_scoreboard(
      event: event,
      rounds: [round],
      tournaments: [tournament],
      sources: { roster: roster, tee_sheet: tee_sheet },
      json_payload: json_payload
    )

    round_data = scoreboard.to_h[:tournaments].first[:entries].first[:rounds]["1615931"]

    assert_equal "9:10 AM", round_data[:tee_time]
  end

  def test_to_h_builds_prestart_entries_from_tee_sheet_when_aggregates_are_empty
    event, round, tournament = setup_mocks
    roster = [
      GolfGenius::RosterMember.construct_from(
        {
          "id" => "101",
          "name" => "Jane Doe",
          "first_name" => "Jane",
          "last_name" => "Doe",
          "member_card_id" => "555",
          "custom_fields" => {
            "city" => "Columbus",
            "state" => "OH",
          },
        }
      ),
    ]
    tee_sheet = [
      GolfGenius::TeeSheetGroup.construct_from(
        {
          "tee_time" => "8:30 AM",
          "players" => [
            {
              "name" => "Jane Doe",
              "player_roster_id" => "101",
              "member_card_id" => "555",
              "score_array" => [],
            },
          ],
        }
      ),
    ]
    json_payload = {
      "name" => "Overall Results",
      "adjusted" => false,
      "rounds" => [],
      "scopes" => [{ "aggregates" => [] }],
    }

    scoreboard = build_scoreboard(
      event: event,
      rounds: [round],
      tournaments: [tournament],
      sources: { roster: roster, tee_sheet: tee_sheet },
      json_payload: json_payload
    )

    tournament_data = scoreboard.to_h[:tournaments].first
    entry = tournament_data[:entries].first
    round_data = entry[:rounds]["1615931"]

    assert_equal 1, tournament_data[:entries].size
    assert_equal "Jane Doe", entry[:name]
    assert_equal "not_started", entry[:state]
    assert_nil entry[:position]
    assert_nil entry[:outcome]
    assert_equal "Columbus", entry[:players].first[:location][:city]
    assert_equal "8:30 AM", round_data[:tee_time]
  end

  def test_to_h_clears_dns_outcome_for_prestart_rows_with_tee_times
    event, round, tournament = setup_mocks
    roster = [
      GolfGenius::RosterMember.construct_from(
        {
          "id" => "101",
          "name" => "Jane Doe",
          "member_card_id" => "555",
          "custom_fields" => {},
        }
      ),
    ]
    tee_sheet = [
      GolfGenius::TeeSheetGroup.construct_from(
        {
          "tee_time" => "8:30 AM",
          "players" => [
            {
              "name" => "Jane Doe",
              "player_roster_id" => "101",
              "member_card_id" => "555",
              "score_array" => [],
            },
          ],
        }
      ),
    ]
    json_payload = {
      "name" => "Overall Results",
      "adjusted" => false,
      "rounds" => [],
      "scopes" => [
        {
          "aggregates" => [
            {
              "id" => 99,
              "name" => "Jane Doe",
              "position" => "",
              "disposition" => "DNS",
              "member_ids" => ["101"],
              "member_cards" => [{ "member_id" => 101, "member_card_id" => 555 }],
              "gross_scores" => Array.new(18),
              "net_scores" => [],
              "to_par_gross" => [],
              "to_par_net" => [],
              "totals" => { "gross_scores" => { "out" => nil, "in" => nil, "total" => nil } },
              "scorecard_statuses" => [{ "member_card_id" => 555, "status" => "no_holes" }],
            },
          ],
        },
      ],
    }

    scoreboard = build_scoreboard(
      event: event,
      rounds: [round],
      tournaments: [tournament],
      sources: { roster: roster, tee_sheet: tee_sheet },
      json_payload: json_payload
    )

    entry = scoreboard.to_h[:tournaments].first[:entries].first

    assert_equal "not_started", entry[:state]
    assert_nil entry[:outcome]
  end

  def test_to_h_normalizes_cut_and_ns_outcomes
    event, round, tournament = setup_mocks
    roster = [
      GolfGenius::RosterMember.construct_from(
        {
          "id" => "101",
          "name" => "Cut Player",
          "member_card_id" => "555",
          "custom_fields" => {},
        }
      ),
      GolfGenius::RosterMember.construct_from(
        {
          "id" => "202",
          "name" => "No Start Player",
          "member_card_id" => "777",
          "custom_fields" => {},
        }
      ),
    ]
    json_payload = {
      "name" => "Overall Results",
      "adjusted" => false,
      "rounds" => [
        { "id" => 1_615_931, "name" => "Round 1", "date" => "2026-03-15", "in_progress" => false },
      ],
      "scopes" => [
        {
          "aggregates" => [
            {
              "id" => 99,
              "name" => "Cut Player",
              "position" => "CUT",
              "member_ids" => ["101"],
              "member_cards" => [{ "member_id" => 101, "member_card_id" => 555 }],
              "rounds" => [{ "id" => 1_615_931, "thru" => "F", "score" => "+4", "total" => "76" }],
              "scorecard_statuses" => [{ "member_card_id" => 555, "status" => "completed" }],
            },
            {
              "id" => 100,
              "name" => "No Start Player",
              "position" => "NS",
              "member_ids" => ["202"],
              "member_cards" => [{ "member_id" => 202, "member_card_id" => 777 }],
              "rounds" => [{ "id" => 1_615_931, "thru" => nil, "score" => nil, "total" => nil }],
              "scorecard_statuses" => [{ "member_card_id" => 777, "status" => "completed" }],
            },
          ],
        },
      ],
    }

    scoreboard = build_scoreboard(
      event: event,
      rounds: [round],
      tournaments: [tournament],
      sources: { roster: roster, tee_sheet: [] },
      json_payload: json_payload
    )

    entries = scoreboard.to_h[:tournaments].first[:entries]
    cut_entry = entries.find { |entry| entry[:id] == "99" }
    ns_entry = entries.find { |entry| entry[:id] == "100" }

    assert_equal "cut", cut_entry[:outcome]
    assert_equal "eliminated", cut_entry[:state]
    assert_equal "finished", cut_entry[:rounds]["1615931"][:state]
    assert_equal "ns", ns_entry[:outcome]
    assert_equal "not_started", ns_entry[:state]
  end

  def test_to_h_maps_unknown_outcome_to_unknown
    event, round, tournament = setup_mocks
    roster = [
      GolfGenius::RosterMember.construct_from(
        {
          "id" => "101",
          "name" => "Mystery Player",
          "member_card_id" => "555",
          "custom_fields" => {},
        }
      ),
    ]
    json_payload = {
      "name" => "Overall Results",
      "adjusted" => false,
      "rounds" => [
        { "id" => 1_615_931, "name" => "Round 1", "date" => "2026-03-15", "in_progress" => false },
      ],
      "scopes" => [
        {
          "aggregates" => [
            {
              "id" => 99,
              "name" => "Mystery Player",
              "position" => "FRC",
              "disposition" => "FRC",
              "member_ids" => ["101"],
              "member_cards" => [{ "member_id" => 101, "member_card_id" => 555 }],
              "rounds" => [{ "id" => 1_615_931, "thru" => "F", "score" => "+2", "total" => "74" }],
              "scorecard_statuses" => [{ "member_card_id" => 555, "status" => "completed" }],
            },
          ],
        },
      ],
    }

    scoreboard = build_scoreboard(
      event: event,
      rounds: [round],
      tournaments: [tournament],
      sources: { roster: roster, tee_sheet: [] },
      json_payload: json_payload
    )

    entry = scoreboard.to_h[:tournaments].first[:entries].first

    assert_equal "unknown", entry[:outcome]
  end

  def test_to_h_does_not_treat_country_as_city
    event, round, tournament = setup_mocks
    roster = [
      GolfGenius::RosterMember.construct_from(
        {
          "id" => "101",
          "name" => "Jane Doe",
          "member_card_id" => "555",
          "custom_fields" => {
            "affiliation" => "Canada",
          },
          "country" => {
            "name" => "Canada",
            "alpha_2" => "CA",
            "alpha_3" => "CAN",
          },
        }
      ),
    ]
    json_payload = {
      "name" => "Overall Results",
      "adjusted" => false,
      "rounds" => [],
      "scopes" => [
        {
          "aggregates" => [
            {
              "id" => 99,
              "name" => "Jane Doe",
              "member_ids" => ["101"],
              "member_cards" => [{ "member_id" => 101, "member_card_id" => 555 }],
              "country" => {
                "name" => "Canada",
                "alpha_2" => "CA",
                "alpha_3" => "CAN",
              },
            },
          ],
        },
      ],
    }

    scoreboard = build_scoreboard(
      event: event,
      rounds: [round],
      tournaments: [tournament],
      sources: { roster: roster, tee_sheet: [] },
      json_payload: json_payload
    )

    location = scoreboard.to_h[:tournaments].first[:entries].first[:players].first[:location]

    assert_equal "country", location[:kind]
    assert_nil location[:city]
    assert_nil location[:state]
    assert_equal "Canada", location[:country][:name]
  end

  def test_to_h_memoizes_result
    event, round, tournament = setup_mocks
    scoreboard = build_scoreboard(event: event, rounds: [round], tournaments: [tournament], json_payload: empty_results_payload)

    first_call = scoreboard.to_h
    second_call = scoreboard.to_h

    assert_same first_call, second_call
  end

  def test_skip_event_fetch_uses_event_id_as_name
    round = create_mock_round("1615931", "Round 1", 1, "2026-03-15")
    tournament = create_mock_tournament("4522280", "Overall Results")

    event_fetch_called = false
    event_fetch_stub = lambda do |*_args|
      event_fetch_called = true
      raise "Event.fetch should not be called when skip_event_fetch: true"
    end

    GolfGenius::Event.stub :fetch, event_fetch_stub do
      GolfGenius::Event.stub :rounds, [round] do
        GolfGenius::Event.stub :tournaments, [tournament] do
          GolfGenius::Event.stub :roster, [] do
            GolfGenius::Event.stub :tee_sheet, [] do
              GolfGenius::Event.stub :tournament_results, stub_tournament_results_json(empty_results_payload) do
                scoreboard = GolfGenius::Scoreboard.new(event: "522157", round: "1615931", skip_event_fetch: true)
                schema = scoreboard.to_h

                refute event_fetch_called
                assert_equal "522157", schema[:meta][:event_name]
              end
            end
          end
        end
      end
    end
  end

  def test_schema_parameter_is_respected
    pre_built_schema = {
      meta: {
        event_id: "522157",
        event_name: "Test Event",
      },
      rounds: [],
      tournaments: [],
    }

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

          assert_equal pre_built_schema, scoreboard.to_h
        end
      end
    end
  end

  def test_resolves_latest_round_from_multiple_rounds
    event = create_mock_event("522157", "Test Event")
    round1 = create_mock_round("1615930", "R1", 1, "2026-03-15", status: "completed")
    round2 = create_mock_round("1615931", "R2", 2, "2026-03-16", status: "in progress")
    round3 = create_mock_round("1615932", "R3", 3, "2026-03-17", status: "not started")
    tournament = create_mock_tournament("4522280", "Overall Results")

    scoreboard = build_scoreboard(
      event: event,
      rounds: [round1, round2, round3],
      tournaments: [tournament],
      json_payload: empty_results_payload
    )

    assert_equal "1615931", scoreboard.to_h[:meta][:selected_round][:id]
  end

  def test_resolves_earliest_upcoming_round_when_nothing_has_started
    event = create_mock_event("522157", "Test Event")
    round1 = create_mock_round("1615930", "R1", 1, "2026-03-15", status: "not started")
    round2 = create_mock_round("1615931", "R2", 2, "2026-03-16", status: "not started")
    tournament = create_mock_tournament("4522280", "Overall Results")

    scoreboard = build_scoreboard(
      event: event,
      rounds: [round1, round2],
      tournaments: [tournament],
      json_payload: empty_results_payload
    )

    assert_equal "1615930", scoreboard.to_h[:meta][:selected_round][:id]
  end

  def test_resolves_all_scoring_tournaments
    event, round, = setup_mocks
    tournament1 = create_mock_tournament("4522280", "Overall Results")
    tournament2 = create_mock_tournament("4522284", "16-18 Results")
    tournament3 = create_mock_tournament("9999", "Pairings")
    def tournament3.non_scoring? = true

    scoreboard = build_scoreboard(
      event: event,
      rounds: [round],
      tournaments: [tournament1, tournament2, tournament3],
      json_payload: empty_results_payload
    )

    scoreboard.to_h

    assert_equal %w[4522280 4522284], scoreboard.instance_variable_get(:@tournament_ids)
  end

  def test_raises_error_when_no_rounds_exist
    event = create_mock_event("522157", "Test Event")

    GolfGenius::Event.stub :fetch, event do
      GolfGenius::Event.stub :rounds, [] do
        scoreboard = GolfGenius::Scoreboard.new(event: "522157")

        error = assert_raises(StandardError) { scoreboard.to_h }

        assert_match(/No rounds found for event/, error.message)
      end
    end
  end

  def test_raises_error_when_no_scoring_tournaments_exist
    round = create_mock_round("1615931", "R1", 1, "2026-03-15")
    tournament = create_mock_tournament("9999", "Pairings Only")
    def tournament.non_scoring? = true

    GolfGenius::Event.stub :rounds, [round] do
      GolfGenius::Event.stub :tournaments, [tournament] do
        scoreboard = GolfGenius::Scoreboard.new(event: "522157", round: "1615931")

        error = assert_raises(StandardError) { scoreboard.to_h }

        assert_match(/No scoring tournaments found/, error.message)
      end
    end
  end

  def test_sort_reuses_schema_without_rebuilding
    event, round, tournament = setup_mocks
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
      stub_tournament_results_json(sortable_results_payload).call(*args)
    end

    GolfGenius::Event.stub :fetch, fetch_stub do
      GolfGenius::Event.stub :rounds, rounds_stub do
        GolfGenius::Event.stub :tournaments, tournaments_stub do
          GolfGenius::Event.stub :roster, [] do
            GolfGenius::Event.stub :tee_sheet, [] do
              GolfGenius::Event.stub :tournament_results, results_stub do
                scoreboard = GolfGenius::Scoreboard.new(event: "522157", round: "1615931")
                original = scoreboard.to_h
                initial_counts = [fetch_count, rounds_count, tournaments_count, results_count]

                sorted = scoreboard.sort(:position)
                sorted_schema = sorted.to_h

                assert_equal initial_counts, [fetch_count, rounds_count, tournaments_count, results_count]
                refute_same original, sorted_schema
                assert_equal(
                  %w[1 2 3],
                  sorted_schema[:tournaments].first[:entries].map { |entry| entry[:position] }
                )
              end
            end
          end
        end
      end
    end
  end

  private

  def setup_mocks
    event = create_mock_event("522157", "Test Event")
    round = create_mock_round("1615931", "R1", 1, "2026-03-15", status: "in progress")
    tournament = create_mock_tournament("4522280", "Overall Results")

    [event, round, tournament]
  end

  def build_scoreboard(json_payload:, event:, rounds:, tournaments:, sources: {})
    roster = sources.fetch(:roster, [])
    tee_sheet = sources.fetch(:tee_sheet, [])

    GolfGenius::Event.stub :fetch, event do
      GolfGenius::Event.stub :rounds, rounds do
        GolfGenius::Event.stub :tournaments, tournaments do
          GolfGenius::Event.stub :roster, roster do
            GolfGenius::Event.stub :tee_sheet, tee_sheet do
              GolfGenius::Event.stub :tournament_results, stub_tournament_results_json(json_payload) do
                scoreboard = GolfGenius::Scoreboard.new(
                  event: event.id,
                  round: rounds.one? ? rounds.first.id : nil
                )
                scoreboard.to_h
                return scoreboard
              end
            end
          end
        end
      end
    end
  end

  def stub_tournament_results_json(json_payload)
    lambda do |*_args|
      json_obj = Object.new
      json_string = JSON.generate(json_payload)
      json_obj.define_singleton_method(:to_json) do |**_kwargs|
        json_string
      end
      json_obj
    end
  end

  def empty_results_payload
    {
      "name" => "Overall Results",
      "adjusted" => false,
      "rounds" => [],
      "scopes" => [{ "aggregates" => [] }],
    }
  end

  def sortable_results_payload
    {
      "name" => "Overall Results",
      "adjusted" => false,
      "rounds" => [
        { "id" => 1_615_931, "name" => "Round 1", "date" => "2026-03-15", "in_progress" => false },
      ],
      "scopes" => [
        {
          "aggregates" => [
            { "id" => 1, "name" => "Player C", "position" => "3", "member_ids" => ["101"], "member_cards" => [] },
            { "id" => 2, "name" => "Player A", "position" => "1", "member_ids" => ["102"], "member_cards" => [] },
            { "id" => 3, "name" => "Player B", "position" => "2", "member_ids" => ["103"], "member_cards" => [] },
          ],
        },
      ],
    }
  end

  def create_mock_event(id, name)
    event = Object.new
    event.define_singleton_method(:id) { id }
    event.define_singleton_method(:[]) do |key|
      [:name, "name"].include?(key) ? name : nil
    end
    event
  end

  def create_mock_round(id, name, index, date, status: "not started")
    round = Object.new
    round.define_singleton_method(:id) { id }
    round.define_singleton_method(:[]) do |key|
      case key
      when :id, "id" then id
      when :name, "name" then name
      when :index, "index" then index
      when :date, "date" then date
      when :status, "status" then status
      when :in_progress, "in_progress" then status == "in progress"
      end
    end
    round.define_singleton_method(:playing?) { status == "in progress" }
    round.define_singleton_method(:started?) { ["in progress", "completed"].include?(status) }
    round.define_singleton_method(:complete?) { status == "completed" }
    round.define_singleton_method(:completed?) { status == "completed" }
    round.define_singleton_method(:unstarted?) { status == "not started" }
    round
  end

  def create_mock_tournament(id, name)
    tournament = Object.new
    tournament.define_singleton_method(:id) { id }
    tournament.define_singleton_method(:[]) { |key| key == :name ? name : nil }
    tournament.define_singleton_method(:non_scoring?) { false }
    tournament
  end
end
