# frozen_string_literal: true

module GolfGenius
  # Represents a Golf Genius event.
  # Events are the primary resource, representing golf tournaments, outings, etc.
  #
  # List parameters (all optional; pass to +list+, +list_all+, +auto_paging_each+):
  # * +:directory+ or +:directory_id+ — Filter to events in this directory (object or id).
  # * +:season+ or +:season_id+ — Filter to events in this season (object or id).
  # * +:category+ or +:category_id+ — Filter to events in this category (object or id).
  # * +:archived+ — +true+ = archived events only; +false+ or omitted = non-archived only (API default).
  # * +:page+ — Request a single page (stops auto-paging); omit to fetch all pages.
  # * +:api_key+ — Override the configured API key.
  #
  # Roster parameters (for +roster(event_id, ...)+): +:page+ (single page), +:photo+ (+true+ to include
  # profile picture URLs; default is no photos).
  #
  # @example List events with filters
  #   events = GolfGenius::Event.list(
  #     directory: dir,
  #     season: season,
  #     archived: false
  #   )
  #
  # @example Archived events only
  #   archived = GolfGenius::Event.list(directory: dir, archived: true)
  #
  # @example Fetch a specific event
  #   event = GolfGenius::Event.fetch('event_123')
  #   puts event.name
  #   puts event.type
  #
  # @example Get event roster
  #   roster = GolfGenius::Event.roster('event_123', photo: true)
  #   roster.each { |player| puts player.name }
  #
  # @example Get event rounds and tournaments
  #   rounds = GolfGenius::Event.rounds('event_123')
  #   tournaments = GolfGenius::Event.tournaments('event_123', 'round_456')
  #
  # @example Iterate through all events
  #   GolfGenius::Event.auto_paging_each(season_id: 'season_123') do |event|
  #     puts event.name
  #   end
  #
  # @see https://www.golfgenius.com/api/v2/docs Golf Genius API Documentation
  class Event < Resource
    # API endpoint path for events
    RESOURCE_PATH = "/events"

    extend APIOperations::List
    extend APIOperations::Fetch
    extend APIOperations::NestedResource

    # Nested resource: Event roster (API returns [ { "member" => {...} } ])
    nested_resource :roster, path: "/events/%<parent_id>s/roster", item_key: "member"

    # Nested resource: Event rounds (API returns [ { "round" => {...} } ])
    nested_resource :rounds, path: "/events/%<parent_id>s/rounds", item_key: "round"

    # Nested resource: Event courses/tees (API returns { "courses" => [...] })
    nested_resource :courses, path: "/events/%<parent_id>s/courses", response_key: "courses"

    # Deeply nested resource: Tournaments for a specific round
    deep_nested_resource :tournaments,
                         path: "/events/%<event_id>s/rounds/%<round_id>s/tournaments",
                         parent_ids: %i[event_id round_id]

    # API returns 100 events per page
    def self.expected_page_size(params)
      params[:per_page] || params[:limit] || 100
    end
  end
end
