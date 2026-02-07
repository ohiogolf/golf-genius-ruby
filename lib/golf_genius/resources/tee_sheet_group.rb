# frozen_string_literal: true

module GolfGenius
  # Represents a pairing group entry in a round tee sheet.
  # Business: A group of players in a round, including tee time, hole, players, and scores.
  # Returned by {Event#tee_sheet} / {Event.tee_sheet} or {Round#tee_sheet}; not a top-level API resource.
  class TeeSheetGroup < GolfGeniusObject
    # Returns the cached event for this tee sheet group, if loaded.
    #
    # @return [Event, nil]
    def event
      @event || fetch_event
    end

    # Returns the cached round for this tee sheet group, if loaded.
    #
    # @return [Round, nil]
    def round
      @round || fetch_round
    end

    # Lazily fetches and caches the event for this tee sheet group.
    # Requires event_id (set when tee sheet comes from event.tee_sheet or round.tee_sheet).
    #
    # @param params [Hash] Optional request params (e.g. api_key)
    # @return [Event]
    # @raise [ArgumentError] if event_id is missing
    def fetch_event(params = {})
      return @event if @event

      event_id = self[:event_id] || self["event_id"]
      if event_id.nil? || event_id.to_s.empty?
        raise ArgumentError, "TeeSheetGroup has no event_id (load via event.tee_sheet to get it)"
      end

      params = params.dup
      params[:api_key] ||= (respond_to?(:api_key, true) ? send(:api_key) : nil)
      @event = Event.fetch(event_id, params)
    end

    # Lazily fetches and caches the round for this tee sheet group.
    # Requires event_id and round_id.
    #
    # @param params [Hash] Optional request params (e.g. api_key)
    # @return [Round]
    # @raise [ArgumentError] if event_id or round_id is missing
    # @raise [NotFoundError] if the round is not found
    def fetch_round(params = {})
      return @round if @round

      event_id, round_id = validate_parent_ids!(%i[event_id round_id], "TeeSheetGroup")
      params = params.dup
      params[:api_key] ||= (respond_to?(:api_key, true) ? send(:api_key) : nil)
      @round = Event.rounds(event_id, params).find { |round| round.id.to_s == round_id.to_s }
      return @round if @round

      raise NotFoundError, "Round not found: #{round_id}"
    end

    def initialize(attributes = {}, api_key: nil)
      super
      normalize_tee_time!
    end

    # Returns tee sheet players as TeeSheetPlayer objects.
    #
    # @return [Array<TeeSheetPlayer>]
    def players
      raw = @attributes[:players]
      return [] if raw.nil?

      Array(raw).filter_map { |item| normalize_player_item(item) }
    end

    # Returns the tee time with surrounding whitespace trimmed.
    #
    # @return [String, nil]
    def tee_time
      @attributes[:tee_time]
    end

    private

    def normalize_tee_time!
      value = @attributes[:tee_time]
      return unless value.is_a?(String)

      @attributes[:tee_time] = value.strip
    end

    def validate_parent_ids!(keys, label)
      keys.map do |key|
        value = self[key] || self[key.to_s]
        if value.nil? || value.to_s.empty?
          raise ArgumentError, "#{label} has no #{key} (load via event.tee_sheet to get it)"
        end

        value
      end
    end

    def normalize_player_item(item)
      return if item.nil?
      return item if item.is_a?(TeeSheetPlayer)

      attrs = item.respond_to?(:to_h) ? item.to_h : item
      return unless attrs.is_a?(Hash) && !attrs.empty?

      TeeSheetPlayer.construct_from(attrs, api_key: api_key)
    end
  end
end
