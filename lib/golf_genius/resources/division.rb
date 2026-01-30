# frozen_string_literal: true

module GolfGenius
  # Represents a division within an event (external divisions from the API).
  #
  # Business: A grouping for play (e.g. flight, tee time block); has name, status, position, tee_times.
  # Returned by {Event#divisions} / {Event.divisions}; not a top-level API resource.
  #
  # @example
  #   divisions = event.divisions
  #   divisions.each { |d| puts "#{d.name}: #{d.status}" }
  #
  # @see Event#divisions
  # @see Event.divisions
  class Division < GolfGeniusObject
  end
end
