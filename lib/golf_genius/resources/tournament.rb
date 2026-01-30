# frozen_string_literal: true

module GolfGenius
  # Represents a tournament within a round (e.g. flight, scoring type).
  # Business: One competition or flight within a single round (e.g. "Gross", "Net Flight A"); defines how that
  # game is scored and ranked. Returned by {Event#tournaments} / {Event.tournaments} or round.tournaments; not a
  # top-level API resource.
  #
  # @example
  #   tournaments = event.tournaments(round_id)
  #   tournaments.each { |t| puts "#{t.name} #{t.scoring}" }
  class Tournament < GolfGeniusObject
  end
end
