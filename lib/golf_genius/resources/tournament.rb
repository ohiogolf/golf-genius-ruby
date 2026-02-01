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
    # Returns the cached event for this tournament, if loaded.
    #
    # @return [Event, nil]
    def event
      @event || fetch_event
    end

    # Returns the cached round for this tournament, if loaded.
    #
    # @return [Round, nil]
    def round
      @round || fetch_round
    end

    # Lazily fetches and caches the event for this tournament.
    # Requires event_id (set when tournament comes from event.tournaments or round.tournaments).
    #
    # @param params [Hash] Optional request params (e.g. api_key)
    # @return [Event]
    # @raise [ArgumentError] if event_id is missing
    def fetch_event(params = {})
      return @event if @event

      event_id = self[:event_id] || self["event_id"]
      if event_id.nil? || event_id.to_s.empty?
        raise ArgumentError, "Tournament has no event_id (load via event.tournaments to get it)"
      end

      params = params.dup
      params[:api_key] ||= (respond_to?(:api_key, true) ? send(:api_key) : nil)
      @event = Event.fetch(event_id, params)
    end

    # Lazily fetches and caches the round for this tournament.
    # Requires event_id and round_id.
    #
    # @param params [Hash] Optional request params (e.g. api_key)
    # @return [Round]
    # @raise [ArgumentError] if event_id or round_id is missing
    # @raise [NotFoundError] if the round is not found
    def fetch_round(params = {})
      return @round if @round

      event_id, round_id = validate_parent_ids!(%i[event_id round_id], "Tournament")
      params = params.dup
      params[:api_key] ||= (respond_to?(:api_key, true) ? send(:api_key) : nil)
      @round = Event.rounds(event_id, params).find { |round| round.id.to_s == round_id.to_s }
      return @round if @round

      raise NotFoundError, "Round not found: #{round_id}"
    end

    # Returns tournament results for this tournament.
    # Defaults to JSON; pass format: :html for HTML.
    # Requires event_id and round_id.
    #
    # @param params [Hash] Optional request params (e.g. api_key, format)
    # @option params [Symbol, String] :format The response format (:json or :html, default: :json)
    # @return [TournamentResults, String] Results payload (object for JSON, string for HTML)
    # @raise [ArgumentError] if event_id or round_id is missing
    def results(params = {})
      event_id, round_id = validate_parent_ids!(%i[event_id round_id], "Tournament")
      params = params.dup
      params[:api_key] ||= (respond_to?(:api_key, true) ? send(:api_key) : nil)
      Event.tournament_results(event_id, round_id, id, params)
    end

    private

    def validate_parent_ids!(keys, label)
      keys.map do |key|
        value = self[key] || self[key.to_s]
        if value.nil? || value.to_s.empty?
          raise ArgumentError, "#{label} has no #{key} (load via event.tournaments to get it)"
        end

        value
      end
    end
  end
end
