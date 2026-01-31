# Changelog

## 1.0.0

Initial stable release focused on read-only API access.

- Read-only API client for Golf Genius API v2.
- List and fetch Seasons, Categories, Directories, Events, and Players.
- Event nested resources: roster, rounds, courses, divisions, tournaments, tee sheet.
- Player roster helpers with typed Handicap and Tee objects.
- Pagination helpers (`list`, `list_all`, `auto_paging_each`).
- `fetch_by` support for alternate identifiers (e.g., Event ggid, Player email).
- Configurable logging, base URL overrides, and raw payload access.
