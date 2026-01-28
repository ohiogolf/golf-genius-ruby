# frozen_string_literal: true

module GolfGenius
  # Represents a Golf Genius event.
  # Events are the primary resource, representing golf tournaments, outings, etc.
  #
  # @example List events with filters
  #   events = GolfGenius::Event.list(
  #     page: 1,
  #     season_id: 'season_123',
  #     archived: false
  #   )
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

    # Nested resource: Event roster
    # GET /api_v2/{api_key}/events/{event_id}/roster
    nested_resource :roster, path: "/events/%<parent_id>s/roster"

    # Nested resource: Event rounds
    # GET /api_v2/{api_key}/events/{event_id}/rounds
    nested_resource :rounds, path: "/events/%<parent_id>s/rounds"

    # Nested resource: Event courses/tees
    # GET /api_v2/{api_key}/events/{event_id}/courses
    nested_resource :courses, path: "/events/%<parent_id>s/courses"

    # Deeply nested resource: Tournaments for a specific round
    # GET /api_v2/{api_key}/events/{event_id}/rounds/{round_id}/tournaments
    deep_nested_resource :tournaments,
                         path: "/events/%<event_id>s/rounds/%<round_id>s/tournaments",
                         parent_ids: %i[event_id round_id]
  end
end
