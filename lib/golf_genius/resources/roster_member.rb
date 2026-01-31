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
    # Returns the member's handicap information as a Handicap object (if present).
    #
    # @return [Handicap, nil]
    def handicap
      typed_value_object(:handicap, Handicap)
    end

    # Returns the member's tee information as a Tee object (if present).
    #
    # @return [Tee, nil]
    def tee
      typed_value_object(:tee, Tee)
    end
  end
end
