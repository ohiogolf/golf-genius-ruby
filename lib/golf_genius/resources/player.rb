# frozen_string_literal: true

module GolfGenius
  # Represents a master roster player.
  # Business: A golfer in the club's master roster; can be listed and looked up by email.
  #
  # List parameters (optional): +:page+ (single page), +:photo+ (+true+ to include profile picture URL), +:api_key+.
  #
  # @example List all players in the master roster
  #   players = GolfGenius::Player.list
  #
  # @example Fetch a player by id (scans master roster pages)
  #   player = GolfGenius::Player.fetch("3925233117178153948")
  #
  # @example Fetch a player by email
  #   player = GolfGenius::Player.fetch_by(email: "john@doe.com")
  #
  # @example Get a player's event ids
  #   summary = GolfGenius::Player.events("1581844")
  #   summary.events # => ["232052", ...]
  #   summary.member # => Player
  #
  # @example Access handicap info
  #   player.handicap.index
  class Player < Resource
    RESOURCE_PATH = "/master_roster"

    extend APIOperations::List
    extend APIOperations::Fetch

    # Fetches a player by email using the master roster member endpoint.
    #
    # @param email [String] Email address of the player
    # @param params [Hash] Optional request params (e.g. api_key)
    # @return [Player]
    def self.fetch_by_email(email, params = {})
      params = params.dup
      api_key = params.delete(:api_key)
      request_params = Util.normalize_request_params(params)
      encoded_email = CGI.escape(email.to_s)

      response = APIOperations::Request.execute(
        method: :get,
        path: "/master_roster_member/#{encoded_email}",
        params: request_params,
        api_key: api_key
      )

      attrs = Util.unwrap_list_item(response, item_key: "member")
      construct_from(attrs, api_key: api_key)
    end

    # Fetches a player by criteria.
    #
    # @param params [Hash] Search criteria (supports :email or :id)
    # @return [Player]
    def self.fetch_by(params = {})
      params = params.dup
      params.delete(:api_key)
      params.delete("api_key")

      email = extract_fetch_by_value(params, :email)
      id = extract_fetch_by_value(params, :id)

      raise ArgumentError, "Pass either id or email" if email && id
      raise ArgumentError, "email or id is required" unless email || id
      raise ArgumentError, "Only email or id is supported" unless params.empty?

      email ? fetch_by_email(email, params) : fetch(id, params)
    end

    # Returns the list of event ids associated with a player.
    #
    # @param player_id [String, Integer] Player id from master roster
    # @param params [Hash] Optional request params (e.g. api_key)
    # @return [GolfGeniusObject] Object with +member+ (Player) and +events+ (Array)
    def self.events(player_id, params = {})
      params = params.dup
      api_key = params.delete(:api_key)
      request_params = Util.normalize_request_params(params)

      response = APIOperations::Request.execute(
        method: :get,
        path: "/players/#{player_id}",
        params: request_params,
        api_key: api_key
      )

      member_attrs = response.is_a?(Hash) ? (response["member"] || response[:member]) : nil
      events = response.is_a?(Hash) ? (response["events"] || response[:events]) : nil
      member = member_attrs ? construct_from(member_attrs, api_key: api_key) : nil

      GolfGeniusObject.construct_from({ member: member, events: events }, api_key: api_key)
    end

    # Returns event ids for this player.
    #
    # @param params [Hash] Optional request params (e.g. api_key)
    # @return [GolfGeniusObject]
    def events(params = {})
      player_id = @attributes[:id]
      raise ArgumentError, "Player has no id" if player_id.nil? || player_id.to_s.empty?

      params = params.dup
      params[:api_key] ||= (respond_to?(:api_key, true) ? send(:api_key) : nil)
      self.class.events(player_id, params)
    end

    # Returns the player's handicap information as a Handicap object (if present).
    #
    # @return [Handicap, nil]
    def handicap
      typed_value_object(:handicap, Handicap)
    end

    # Returns the player's tee information as a Tee object (if present).
    #
    # @return [Tee, nil]
    def tee
      typed_value_object(:tee, Tee)
    end

    private_class_method def self.fetch_page(params)
      params = params.dup
      api_key = params.delete(:api_key)
      request_params = Util.normalize_request_params(params)

      response = APIOperations::Request.execute(
        method: :get,
        path: resource_path,
        params: request_params,
        api_key: api_key
      )

      data = Util.extract_data_array(response)
      data.map do |item|
        attrs = Util.unwrap_list_item(item, item_key: "member")
        construct_from(attrs, api_key: api_key)
      end
    end

    private_class_method def self.extract_fetch_by_value(params, key)
      params.delete(key) || params.delete(key.to_s)
    end
  end
end
