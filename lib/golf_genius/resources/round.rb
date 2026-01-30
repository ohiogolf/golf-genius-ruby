# frozen_string_literal: true

module GolfGenius
  # Represents a round within an event.
  # Business: One day (or unit) of play; has its own date, tee sheet, and tournaments (scoring games).
  # Returned by {Event#rounds} / {Event.rounds}; has event_id when loaded that way so you can call round.tournaments.
  #
  # @example
  #   rounds = event.rounds
  #   rounds.each { |r| puts "#{r.id} #{r.date} #{r.status}" }
  #   round.tournaments  # => [Tournament, ...] when round has event_id (from event.rounds)
  class Round < GolfGeniusObject
    # Returns tournaments for this round. Requires event_id (set when round comes from event.rounds).
    #
    # @param params [Hash] Optional request params (e.g. api_key)
    # @return [Array<Tournament>]
    # @raise [ArgumentError] if event_id is missing
    def tournaments(params = {})
      event_id = self[:event_id] || self["event_id"]
      if event_id.nil? || event_id.to_s.empty?
        raise ArgumentError, "Round has no event_id (load via event.rounds to get it)"
      end

      params = params.dup
      params[:api_key] ||= (respond_to?(:api_key, true) ? send(:api_key) : nil)
      Event.tournaments(event_id, id, params)
    end
  end
end
