# frozen_string_literal: true

module GolfGenius
  # Represents a member on an event roster.
  # Business: A player registered for the event; carries their event-level info (handicap, custom fields, photo).
  # Returned by {Event#roster} / {Event.roster}; not a top-level API resource.
  #
  # @example
  #   roster = event.roster(photo: true)
  #   roster.each { |m| puts "#{m.name}: #{m.photo_url}" }
  class RosterMember < GolfGeniusObject
  end
end
