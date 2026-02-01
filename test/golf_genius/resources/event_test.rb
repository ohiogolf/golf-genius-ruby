# frozen_string_literal: true

require "test_helper"

class EventTest < Minitest::Test
  def setup
    setup_test_configuration
  end

  def teardown
    GolfGenius.reset_configuration!
  end

  def test_list_events
    stub_api_request(method: :get, path: "/events", response_body: EVENTS, query: { "page" => "1" })
    stub_api_request(method: :get, path: "/events", response_body: [], query: { "page" => "2" })

    events = GolfGenius::Event.list

    assert_kind_of Array, events
    assert_equal 2, events.length
    assert_kind_of GolfGenius::Event, events.first
    assert_equal "event_001", events.first.id
    assert_equal "Spring Championship", events.first.name
  end

  def test_list_events_with_filters
    stub_api_request(
      method: :get,
      path: "/events",
      response_body: EVENTS,
      query: { "page" => "1", "season" => "season_001", "archived" => "false" }
    )

    events = GolfGenius::Event.list(page: 1, season_id: "season_001", archived: false)

    assert_kind_of Array, events
  end

  def test_list_events_accepts_resource_objects
    dir = GolfGenius::Directory.construct_from(GolfGenius::TestFixtures::DIRECTORY)
    stub_api_request(
      method: :get,
      path: "/events",
      response_body: EVENTS,
      query: { "directory" => "dir_001", "page" => "1" }
    )
    stub_api_request(
      method: :get,
      path: "/events",
      response_body: [],
      query: { "directory" => "dir_001", "page" => "2" }
    )

    events = GolfGenius::Event.list(directory: dir)

    assert_kind_of Array, events
    assert_equal 2, events.length
  end

  def test_fetch_event
    stub_api_request(method: :get, path: "/events", response_body: EVENTS, query: { "page" => "1" })

    event = GolfGenius::Event.fetch("event_001")

    assert_kind_of GolfGenius::Event, event
    assert_equal "event_001", event.id
    assert_equal "Spring Championship", event.name
    assert_equal "tournament", event.type
  end

  def test_fetch_event_falls_back_to_archived
    archived_events = [EVENT.merge("archived" => true)]
    stub_api_request(method: :get, path: "/events", response_body: [], query: { "page" => "1" })
    stub_api_request(method: :get, path: "/events", response_body: archived_events, query: { "page" => "1", "archived" => "true" })

    event = GolfGenius::Event.fetch("event_001")

    assert_kind_of GolfGenius::Event, event
    assert_equal "event_001", event.id
    assert_equal true, event.archived
  end

  def test_fetch_event_respects_archived_param
    archived_events = [EVENT.merge("archived" => true)]
    stub_api_request(method: :get, path: "/events", response_body: archived_events, query: { "page" => "1", "archived" => "true" })

    event = GolfGenius::Event.fetch("event_001", archived: true)

    assert_kind_of GolfGenius::Event, event
    assert_equal "event_001", event.id
    assert_equal true, event.archived
  end

  def test_fetch_event_respects_archived_false
    stub_api_request(method: :get, path: "/events", response_body: EVENTS, query: { "page" => "1", "archived" => "false" })

    event = GolfGenius::Event.fetch("event_001", archived: false)

    assert_kind_of GolfGenius::Event, event
    assert_equal "event_001", event.id
  end

  def test_fetch_event_by_ggid
    events_with_ggid = [EVENT.merge("ggid" => "zphsqa")]
    stub_api_request(method: :get, path: "/events", response_body: events_with_ggid, query: { "page" => "1" })

    event = GolfGenius::Event.fetch_by(ggid: "zphsqa")

    assert_kind_of GolfGenius::Event, event
    assert_equal "event_001", event.id
    assert_equal "zphsqa", event.ggid
  end

  def test_fetch_event_by_ggid_falls_back_to_archived
    archived_events = [EVENT.merge("ggid" => "zphsqa", "archived" => true)]
    stub_api_request(method: :get, path: "/events", response_body: [], query: { "page" => "1" })
    stub_api_request(method: :get, path: "/events", response_body: archived_events, query: { "page" => "1", "archived" => "true" })

    event = GolfGenius::Event.fetch_by(ggid: "zphsqa")

    assert_kind_of GolfGenius::Event, event
    assert_equal "event_001", event.id
    assert_equal "zphsqa", event.ggid
    assert_equal true, event.archived
  end

  def test_fetch_event_by_ggid_respects_archived_false
    events_with_ggid = [EVENT.merge("ggid" => "zphsqa")]
    stub_api_request(method: :get, path: "/events", response_body: events_with_ggid, query: { "page" => "1", "archived" => "false" })

    event = GolfGenius::Event.fetch_by(ggid: "zphsqa", archived: false)

    assert_kind_of GolfGenius::Event, event
    assert_equal "event_001", event.id
    assert_equal "zphsqa", event.ggid
  end

  def test_fetch_event_by_ggid_respects_archived_true
    archived_events = [EVENT.merge("ggid" => "zphsqa", "archived" => true)]
    stub_api_request(method: :get, path: "/events", response_body: archived_events, query: { "page" => "1", "archived" => "true" })

    event = GolfGenius::Event.fetch_by(ggid: "zphsqa", archived: true)

    assert_kind_of GolfGenius::Event, event
    assert_equal "event_001", event.id
    assert_equal "zphsqa", event.ggid
    assert_equal true, event.archived
  end

  def test_fetch_event_raises_when_not_found
    stub_api_request(method: :get, path: "/events", response_body: [], query: { "page" => "1" })
    stub_api_request(method: :get, path: "/events", response_body: [], query: { "page" => "1", "archived" => "true" })

    error = assert_raises(GolfGenius::NotFoundError) do
      GolfGenius::Event.fetch("nonexistent")
    end

    assert_includes error.message, "Resource not found"
    assert_includes error.message, "nonexistent"
  end

  def test_event_nested_season
    event = GolfGenius::Event.construct_from(EVENT)

    assert_kind_of GolfGenius::Season, event.season
    assert_equal "season_001", event.season.id
    assert_equal "2026 Season", event.season.name
  end

  def test_event_nested_category
    event = GolfGenius::Event.construct_from(EVENT)

    assert_kind_of GolfGenius::Category, event.category
    assert_equal "cat_001", event.category.id
    assert_equal "Member Events", event.category.name
    assert_equal "#FF5733", event.category.color
  end

  def test_event_directories_typed
    event_data = EVENT.merge("directories" => [{ "directory" => { "id" => "dir_001", "name" => "Main Directory" } }])
    event = GolfGenius::Event.construct_from(event_data)

    dirs = event.directories

    assert_kind_of Array, dirs
    assert_equal 1, dirs.length
    assert_kind_of GolfGenius::Directory, dirs.first
    assert_equal "dir_001", dirs.first.id
    assert_equal "Main Directory", dirs.first.name
  end

  def test_event_roster
    stub_api_request(
      method: :get,
      path: "/events/event_001/roster",
      response_body: EVENT_ROSTER_WITH_DETAILS,
      query: { "page" => "1" }
    )

    roster = GolfGenius::Event.roster("event_001")

    assert_kind_of Array, roster
    assert_equal 3, roster.length
    assert_kind_of GolfGenius::RosterMember, roster.first
    assert_equal "player_001", roster.first.id
    assert_equal "John Smith", roster.first.name
    assert_kind_of GolfGenius::Handicap, roster.first.handicap
    assert_equal "12.5", roster.first.handicap.index
    assert_kind_of GolfGenius::Tee, roster.first.tee
    assert_equal "Blue", roster.first.tee.name
  end

  def test_event_roster_with_params
    stub_api_request(
      method: :get,
      path: "/events/event_001/roster",
      response_body: EVENT_ROSTER_WITH_DETAILS,
      query: { "page" => "1", "photo" => "true" }
    )

    roster = GolfGenius::Event.roster("event_001", photo: true)

    assert_equal 3, roster.length
    assert_kind_of GolfGenius::Handicap, roster.first.handicap
    assert_kind_of GolfGenius::Tee, roster.first.tee
  end

  def test_event_roster_paginates_all_pages
    page1 = (1..100).map { |i| { "id" => "p#{i}", "name" => "Player #{i}" } }
    page2 = (1..76).map { |i| { "id" => "p#{100 + i}", "name" => "Player #{100 + i}" } }
    stub_api_request(
      method: :get,
      path: "/events/event_001/roster",
      response_body: page1,
      query: { "page" => "1" }
    )
    stub_api_request(
      method: :get,
      path: "/events/event_001/roster",
      response_body: page2,
      query: { "page" => "2" }
    )

    roster = GolfGenius::Event.roster("event_001")

    assert_equal 176, roster.length
    assert_equal "p1", roster.first.id
    assert_equal "p176", roster.last.id
  end

  def test_event_roster_photo_url_alias
    roster_with_photo = [
      { "member" => { "id" => "p1", "name" => "Jane", "photo" => "https://example.com/photo.jpg" } },
      { "member" => { "id" => "p2", "name" => "Joe", "photo" => nil } },
    ]
    stub_api_request(
      method: :get,
      path: "/events/event_001/roster",
      response_body: roster_with_photo,
      query: { "page" => "1", "photo" => "true" }
    )

    roster = GolfGenius::Event.roster("event_001", photo: true)

    assert_equal "https://example.com/photo.jpg", roster.first.photo_url
    assert_nil roster.last.photo_url
  end

  def test_event_roster_waitlist_filter
    # API returns both confirmed and waitlisted; :waitlist is not sent to API, filtered client-side
    roster_with_waitlist = [
      { "id" => "p1", "name" => "Confirmed One", "waitlist" => false },
      { "id" => "p2", "name" => "Waitlisted One", "waitlist" => true },
      { "id" => "p3", "name" => "Confirmed Two", "waitlist" => false },
    ]
    stub_api_request(
      method: :get,
      path: "/events/event_001/roster",
      response_body: roster_with_waitlist,
      query: { "page" => "1" }
    )

    confirmed = GolfGenius::Event.roster("event_001", waitlist: false)

    assert_equal 2, confirmed.length
    assert_equal %w[p1 p3], confirmed.map(&:id)
    assert(confirmed.all? { |m| m.waitlist == false })
  end

  def test_event_roster_scalar_values
    stub_api_request(
      method: :get,
      path: "/events/event_001/roster",
      response_body: EVENT_ROSTER,
      query: { "page" => "1" }
    )

    roster = GolfGenius::Event.roster("event_001")

    assert_equal 3, roster.length
    assert_in_delta(12.5, roster.first.handicap)
    assert_equal "Blue", roster.first.tee
  end

  def test_event_instance_roster
    stub_api_request(
      method: :get,
      path: "/events/event_001/roster",
      response_body: EVENT_ROSTER_WITH_DETAILS,
      query: { "page" => "1" }
    )

    event = GolfGenius::Event.construct_from(EVENT)
    roster = event.roster

    assert_kind_of Array, roster
    assert_equal 3, roster.length
    assert_equal "player_001", roster.first.id
  end

  def test_event_instance_rounds
    stub_api_request(method: :get, path: "/events/event_001/rounds", response_body: EVENT_ROUNDS, query: { "page" => "1" })

    event = GolfGenius::Event.construct_from(EVENT)
    rounds = event.rounds

    assert_kind_of Array, rounds
    assert_equal 2, rounds.length
    assert_equal "round_001", rounds.first.id
  end

  def test_event_instance_courses
    stub_api_request(method: :get, path: "/events/event_001/courses", response_body: EVENT_COURSES, query: { "page" => "1" })

    event = GolfGenius::Event.construct_from(EVENT)
    courses = event.courses

    assert_kind_of Array, courses
    assert_equal 2, courses.length
  end

  def test_event_tee_sheet
    stub_api_request(
      method: :get,
      path: "/events/event_001/rounds/round_001/tee_sheet",
      response_body: TEE_SHEET,
      query: { "page" => "1" }
    )
    stub_api_request(
      method: :get,
      path: "/events/event_001/rounds/round_001/tee_sheet",
      response_body: [],
      query: { "page" => "2" }
    )

    tee_sheet = GolfGenius::Event.tee_sheet("event_001", "round_001")

    assert_kind_of Array, tee_sheet
    assert_equal 2, tee_sheet.length
    assert_kind_of GolfGenius::TeeSheetGroup, tee_sheet.first
    assert_equal "group_001", tee_sheet.first.id
    assert_equal 1, tee_sheet.first.hole
    assert_equal "8:30 AM", tee_sheet.first.tee_time
    assert_kind_of Array, tee_sheet.first.players
    assert_kind_of GolfGenius::TeeSheetPlayer, tee_sheet.first.players.first
    assert_equal "Wood, Tim", tee_sheet.first.players.first.name
  end

  def test_event_tee_sheet_with_params
    stub_api_request(
      method: :get,
      path: "/events/event_001/rounds/round_001/tee_sheet",
      response_body: TEE_SHEET,
      query: { "include_all_custom_fields" => "true", "page" => "1" }
    )
    stub_api_request(
      method: :get,
      path: "/events/event_001/rounds/round_001/tee_sheet",
      response_body: [],
      query: { "include_all_custom_fields" => "true", "page" => "2" }
    )

    tee_sheet = GolfGenius::Event.tee_sheet("event_001", "round_001", include_all_custom_fields: true)

    assert_equal 2, tee_sheet.length
  end

  def test_event_divisions
    stub_api_request(
      method: :get,
      path: "/events/event_001/divisions",
      response_body: EVENT_DIVISIONS
    )

    divisions = GolfGenius::Event.divisions("event_001")

    assert_kind_of Array, divisions
    assert_equal 2, divisions.length
    assert_kind_of GolfGenius::Division, divisions.first
    assert_equal "2794531013441653808", divisions.first.id
    assert_equal "Division Test", divisions.first.name
    assert_equal "not started", divisions.first.status
    assert_equal 0, divisions.first.position
    assert_equal "div_002", divisions.last.id
    assert_equal "Flight B", divisions.last.name
  end

  def test_event_instance_divisions
    stub_api_request(
      method: :get,
      path: "/events/event_001/divisions",
      response_body: EVENT_DIVISIONS
    )

    event = GolfGenius::Event.construct_from(EVENT)
    divisions = event.divisions

    assert_kind_of Array, divisions
    assert_equal 2, divisions.length
    assert_kind_of GolfGenius::Division, divisions.first
    assert_equal "Division Test", divisions.first.name
  end

  def test_event_instance_tournaments
    stub_api_request(method: :get, path: "/events/event_001/rounds/round_001/tournaments", response_body: TOURNAMENTS, query: { "page" => "1" })

    event = GolfGenius::Event.construct_from(EVENT)
    tournaments = event.tournaments("round_001")

    assert_kind_of Array, tournaments
    assert_equal 2, tournaments.length
    assert_equal "tourn_001", tournaments.first.id
  end

  def test_event_instance_tournaments_requires_round_id
    event = GolfGenius::Event.construct_from(EVENT)

    error = assert_raises(ArgumentError) { event.tournaments }
    assert_match(/tournaments requires 1 argument/, error.message)
    assert_match(/round_id/, error.message)
  end

  def test_event_tournaments_accepts_round_object
    stub_api_request(method: :get, path: "/events/event_001/rounds/round_001/tournaments", response_body: TOURNAMENTS, query: { "page" => "1" })

    event = GolfGenius::Event.construct_from(EVENT)
    round = GolfGenius::Round.construct_from({ "id" => "round_001" })

    tournaments = event.tournaments(round)

    assert_equal 2, tournaments.length
    assert_equal "tourn_001", tournaments.first.id
  end

  def test_event_tournaments_accepts_round_keyword
    stub_api_request(method: :get, path: "/events/event_001/rounds/round_001/tournaments", response_body: TOURNAMENTS, query: { "page" => "1" })

    event = GolfGenius::Event.construct_from(EVENT)
    round = GolfGenius::Round.construct_from({ "id" => "round_001" })

    tournaments = event.tournaments(round: round)

    assert_equal 2, tournaments.length
    assert_equal "tourn_001", tournaments.first.id
  end

  def test_round_tournaments_from_event_rounds
    stub_api_request(method: :get, path: "/events/event_001/rounds", response_body: EVENT_ROUNDS, query: { "page" => "1" })
    stub_api_request(method: :get, path: "/events/event_001/rounds/round_001/tournaments", response_body: TOURNAMENTS, query: { "page" => "1" })

    event = GolfGenius::Event.construct_from(EVENT)
    round = event.rounds.first

    assert_kind_of GolfGenius::Round, round
    assert_equal "event_001", round[:event_id]

    tournaments = round.tournaments

    assert_kind_of Array, tournaments
    assert_equal 2, tournaments.length
    assert_kind_of GolfGenius::Tournament, tournaments.first
    assert_equal "tourn_001", tournaments.first.id
  end

  def test_round_tee_sheet_from_event_rounds
    stub_api_request(method: :get, path: "/events/event_001/rounds", response_body: EVENT_ROUNDS, query: { "page" => "1" })
    stub_api_request(method: :get, path: "/events/event_001/rounds/round_001/tee_sheet", response_body: TEE_SHEET, query: { "page" => "1" })
    stub_api_request(method: :get, path: "/events/event_001/rounds/round_001/tee_sheet", response_body: [], query: { "page" => "2" })

    event = GolfGenius::Event.construct_from(EVENT)
    round = event.rounds.first

    assert_kind_of GolfGenius::Round, round
    assert_equal "event_001", round[:event_id]

    tee_sheet = round.tee_sheet

    assert_kind_of Array, tee_sheet
    assert_equal 2, tee_sheet.length
    assert_kind_of GolfGenius::TeeSheetGroup, tee_sheet.first
    assert_equal "group_001", tee_sheet.first.id
  end

  def test_round_tee_sheet_raises_without_event_id
    round = GolfGenius::Round.construct_from({ "id" => "round_001" })

    error = assert_raises(ArgumentError) { round.tee_sheet }
    assert_match(/event_id/, error.message)
  end

  def test_round_tournaments_raises_without_event_id
    round = GolfGenius::Round.construct_from({ "id" => "round_001" })

    error = assert_raises(ArgumentError) { round.tournaments }
    assert_match(/event_id/, error.message)
  end

  def test_event_rounds
    stub_api_request(method: :get, path: "/events/event_001/rounds", response_body: EVENT_ROUNDS, query: { "page" => "1" })

    rounds = GolfGenius::Event.rounds("event_001")

    assert_kind_of Array, rounds
    assert_equal 2, rounds.length
    assert_kind_of GolfGenius::Round, rounds.first
    assert_equal "round_001", rounds.first.id
    assert_equal 1, rounds.first.number
  end

  def test_event_rounds_sorted_by_index
    # API returns rounds in reverse index order; we should return them sorted by index
    rounds_reversed = [
      { "id" => "round_002", "index" => 2, "name" => "Round 2" },
      { "id" => "round_001", "index" => 1, "name" => "Round 1" },
    ]
    stub_api_request(method: :get, path: "/events/event_001/rounds", response_body: rounds_reversed, query: { "page" => "1" })

    rounds = GolfGenius::Event.rounds("event_001")

    assert_equal 2, rounds.length
    assert_equal 1, rounds.first.index
    assert_equal "round_001", rounds.first.id
    assert_equal 2, rounds.last.index
    assert_equal "round_002", rounds.last.id
  end

  def test_event_courses
    stub_api_request(method: :get, path: "/events/event_001/courses", response_body: EVENT_COURSES, query: { "page" => "1" })

    courses = GolfGenius::Event.courses("event_001")

    assert_kind_of Array, courses
    assert_equal 2, courses.length
    assert_kind_of GolfGenius::Course, courses.first
    assert_equal "course_001", courses.first.id
    assert_in_delta(74.5, courses.first.rating)
  end

  def test_event_tournaments
    stub_api_request(method: :get, path: "/events/event_001/rounds/round_001/tournaments", response_body: TOURNAMENTS, query: { "page" => "1" })

    tournaments = GolfGenius::Event.tournaments("event_001", "round_001")

    assert_kind_of Array, tournaments
    assert_equal 2, tournaments.length
    assert_kind_of GolfGenius::Tournament, tournaments.first
    assert_equal "tourn_001", tournaments.first.id
    assert_equal "Flight A - Gross", tournaments.first.name
  end

  def test_auto_paging_each
    # Stub page 1 (full page of 25 items)
    stub_api_request(
      method: :get,
      path: "/events",
      response_body: EVENTS_PAGE_1,
      query: { "page" => "1", "per_page" => "25" }
    )

    # Stub page 2 (partial page of 5 items - indicates last page)
    stub_api_request(
      method: :get,
      path: "/events",
      response_body: EVENTS_PAGE_2,
      query: { "page" => "2", "per_page" => "25" }
    )

    collected = []
    GolfGenius::Event.auto_paging_each(page: 1, per_page: 25) do |event|
      collected << event
    end

    assert_equal 30, collected.length
    assert_equal "event_001", collected.first.id
    assert_equal "event_030", collected.last.id
  end

  def test_auto_paging_each_returns_enumerator
    stub_api_request(
      method: :get,
      path: "/events",
      response_body: EVENTS,
      query: { page: "1" }
    )

    enumerator = GolfGenius::Event.auto_paging_each(page: 1)

    assert_kind_of Enumerator, enumerator
  end

  def test_list_all
    stub_api_request(
      method: :get,
      path: "/events",
      response_body: EVENTS_PAGE_1,
      query: { "page" => "1", "per_page" => "25" }
    )

    stub_api_request(
      method: :get,
      path: "/events",
      response_body: EVENTS_PAGE_2,
      query: { "page" => "2", "per_page" => "25" }
    )

    all_events = GolfGenius::Event.list_all(page: 1, per_page: 25)

    assert_kind_of Array, all_events
    assert_equal 30, all_events.length
  end
end
