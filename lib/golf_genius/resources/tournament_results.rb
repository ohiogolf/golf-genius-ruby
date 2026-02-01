# frozen_string_literal: true

module GolfGenius
  # Represents tournament results for a specific round tournament.
  # Business: Raw results payload returned by the tournament results endpoint.
  class TournamentResults < GolfGeniusObject
    # Returns the cached event for these results, if loaded.
    #
    # @return [Event, nil]
    def event
      @event || fetch_event
    end

    # Returns the cached round for these results, if loaded.
    #
    # @return [Round, nil]
    def round
      @round || fetch_round
    end

    # Returns the cached tournament for these results, if loaded.
    #
    # @return [Tournament, nil]
    def tournament
      @tournament || fetch_tournament
    end

    # Lazily fetches and caches the event for these results.
    # Requires event_id.
    #
    # @param params [Hash] Optional request params (e.g. api_key)
    # @return [Event]
    # @raise [ArgumentError] if event_id is missing
    def fetch_event(params = {})
      return @event if @event

      event_id = self[:event_id] || self["event_id"]
      if event_id.nil? || event_id.to_s.empty?
        raise ArgumentError, "TournamentResults has no event_id (load via event.tournament_results to get it)"
      end

      params = params.dup
      params[:api_key] ||= (respond_to?(:api_key, true) ? send(:api_key) : nil)
      @event = Event.fetch(event_id, params)
    end

    # Lazily fetches and caches the round for these results.
    # Requires event_id and round_id.
    #
    # @param params [Hash] Optional request params (e.g. api_key)
    # @return [Round]
    # @raise [ArgumentError] if event_id or round_id is missing
    # @raise [NotFoundError] if the round is not found
    def fetch_round(params = {})
      return @round if @round

      event_id, round_id = validate_parent_ids!(%i[event_id round_id], "TournamentResults")
      params = params.dup
      params[:api_key] ||= (respond_to?(:api_key, true) ? send(:api_key) : nil)
      @round = Event.rounds(event_id, params).find { |round| round.id.to_s == round_id.to_s }
      return @round if @round

      raise NotFoundError, "Round not found: #{round_id}"
    end

    # Lazily fetches and caches the tournament for these results.
    # Requires event_id, round_id, and tournament_id.
    #
    # @param params [Hash] Optional request params (e.g. api_key)
    # @return [Tournament]
    # @raise [ArgumentError] if event_id, round_id, or tournament_id is missing
    # @raise [NotFoundError] if the tournament is not found
    def fetch_tournament(params = {})
      return @tournament if @tournament

      event_id, round_id, tournament_id = validate_parent_ids!(%i[event_id round_id tournament_id], "TournamentResults")
      params = params.dup
      params[:api_key] ||= (respond_to?(:api_key, true) ? send(:api_key) : nil)
      @tournament = Event.tournaments(event_id, round_id, params).find do |tournament|
        tournament.id.to_s == tournament_id.to_s
      end
      return @tournament if @tournament

      raise NotFoundError, "Tournament not found: #{tournament_id}"
    end

    private

    def validate_parent_ids!(keys, label)
      keys.map do |key|
        value = self[key] || self[key.to_s]
        if value.nil? || value.to_s.empty?
          raise ArgumentError, "#{label} has no #{key} (load via event.tournament_results to get it)"
        end

        value
      end
    end
  end
end
