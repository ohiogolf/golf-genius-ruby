# Changelog

## 1.1.0

Scoreboard module for parsing tournament results into structured leaderboards.

### Added

- `GolfGenius::Scoreboard` — fetches HTML and JSON tournament results, merges
  them into typed value objects (Tournament, Row, Cell, Column, Scorecard).
- `Event.tournament_results` — fetch tournament results in HTML or JSON format.
- `Event#latest_round` — resolve the most recent round for an event.
- `Tournament#non_scoring?` — detect pairings sheets and scorecard-printing
  tournaments by name heuristics.
- `Round#playing?`, `Round#completed?`, `Round#unstarted?`, `Round#started?` —
  round status predicates.
- Row status helpers: `competing?`, `eliminated?`, `cut?`, `withdrew?`,
  `disqualified?`, `no_show?`, `no_card?`.
- Par-relative helpers on Cell and Scorecard (`under_par?`, `over_par?`,
  `even_par?`, `to_par`).
- Multi-key sorting on Tournament and Scoreboard (`:position`, `:last_name`,
  `:competing`).
- WD/CUT display logic with `elimination_round` tracking.
- `bin/export-tournament-results` script for bulk CSV export.
- `docs/scoreboard-usage-guide.md` with full usage examples.

### Changed

- `Util.normalize_request_params` now covers all resource types (event, round,
  tournament, player, course, division, etc.).
- API key validation rejects empty strings.
- `bin/console` and `bin/export-tournament-results` default to production
  environment.
- Added `nokogiri ~> 1.13` runtime dependency.

## 1.0.0

Initial stable release focused on read-only API access.

- Read-only API client for Golf Genius API v2.
- List and fetch Seasons, Categories, Directories, Events, and Players.
- Event nested resources: roster, rounds, courses, divisions, tournaments, tee sheet.
- Player roster helpers with typed Handicap and Tee objects.
- Pagination helpers (`list`, `list_all`, `auto_paging_each`).
- `fetch_by` support for alternate identifiers (e.g., Event ggid, Player email).
- Configurable logging, base URL overrides, and raw payload access.
