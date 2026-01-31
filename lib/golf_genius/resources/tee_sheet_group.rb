# frozen_string_literal: true

module GolfGenius
  # Represents a pairing group entry in a round tee sheet.
  # Business: A group of players in a round, including tee time, hole, players, and scores.
  # Returned by {Event#tee_sheet} / {Event.tee_sheet} or {Round#tee_sheet}; not a top-level API resource.
  class TeeSheetGroup < GolfGeniusObject
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

    def normalize_player_item(item)
      return if item.nil?
      return item if item.is_a?(TeeSheetPlayer)

      attrs = item.respond_to?(:to_h) ? item.to_h : item
      return unless attrs.is_a?(Hash) && !attrs.empty?

      TeeSheetPlayer.construct_from(attrs, api_key: api_key)
    end
  end
end
