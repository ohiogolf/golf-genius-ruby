# frozen_string_literal: true

module GolfGenius
  # Client for interacting with the Golf Genius API.
  # Use this when you need to work with multiple API keys or prefer
  # an instance-based approach over the module-level methods.
  #
  # @example Basic usage
  #   client = GolfGenius::Client.new(api_key: 'your_api_key')
  #   seasons = client.seasons.list
  #   event = client.events.fetch(171716)
  #
  # @example Multiple clients with different API keys
  #   client1 = GolfGenius::Client.new(api_key: 'key_for_org_1')
  #   client2 = GolfGenius::Client.new(api_key: 'key_for_org_2')
  #
  # @see https://www.golfgenius.com/api/v2/docs Golf Genius API Documentation
  class Client
    # @return [String] The API key for this client
    attr_reader :api_key

    # Creates a new Golf Genius API client.
    #
    # @param api_key [String, nil] The API key to use. Falls back to GolfGenius.api_key if not provided.
    # @raise [ConfigurationError] If no API key is available
    def initialize(api_key: nil)
      @api_key = api_key || GolfGenius.api_key
      raise ConfigurationError, "API key is required" unless @api_key
    end

    # Inspect without exposing the API key.
    #
    # @return [String]
    def inspect
      "#<#{self.class} api_key=[REDACTED-API-KEY]>"
    end

    # Access to Season resources.
    #
    # @return [ResourceProxy] Proxy for Season operations
    #
    # @example
    #   client.seasons.list
    #   client.seasons.fetch('season_123')
    def seasons
      @seasons ||= ResourceProxy.new(Season, @api_key)
    end

    # Access to Category resources.
    #
    # @return [ResourceProxy] Proxy for Category operations
    #
    # @example
    #   client.categories.list
    #   client.categories.fetch('category_123')
    def categories
      @categories ||= ResourceProxy.new(Category, @api_key)
    end

    # Access to Directory resources.
    #
    # @return [ResourceProxy] Proxy for Directory operations
    #
    # @example
    #   client.directories.list
    #   client.directories.fetch('directory_123')
    def directories
      @directories ||= ResourceProxy.new(Directory, @api_key)
    end

    # Access to Player resources (master roster).
    #
    # @return [ResourceProxy] Proxy for Player operations
    #
    # @example
    #   client.players.list
    #   client.players.fetch('player_123')
    #   client.players.fetch_by(email: 'john@doe.com')
    #   client.players.fetch_by(id: 'player_123')
    #   client.players.events('player_123')
    def players
      @players ||= PlayerProxy.new(Player, @api_key)
    end

    # Access to Event resources.
    #
    # @return [ResourceProxy] Proxy for Event operations
    #
    # @example
    #   client.events.list(page: 1)
    #   client.events.fetch(171716)
    #   client.events.fetch_by(ggid: 'zphsqa')
    #   client.events.roster('event_123')
    #   client.events.rounds('event_123')
    def events
      @events ||= ResourceProxy.new(Event, @api_key)
    end

    # Internal class to proxy resource calls with the client's API key.
    # Provides explicit method delegation for better discoverability and IDE support.
    #
    # @api private
    class ResourceProxy
      # @param resource_class [Class] The resource class to proxy
      # @param api_key [String] The API key to use for all requests
      def initialize(resource_class, api_key)
        @resource_class = resource_class
        @api_key = api_key
      end

      # Lists resources.
      #
      # @param params [Hash] Query parameters for filtering/pagination
      # @return [Array<Resource>] Array of resource instances
      def list(params = {})
        @resource_class.list(params.merge(api_key: @api_key))
      end

      # Fetches a single resource by id (uses list endpoint).
      #
      # @param id [String, Integer] Resource id
      # @param params [Hash] Optional list filters (e.g. season_id, max_pages)
      # @return [Resource] The matching resource
      # @raise [NotFoundError] If no resource matches
      def fetch(id, params = {})
        @resource_class.fetch(id, params.merge(api_key: @api_key))
      end

      # Fetches a single resource by attribute (uses list endpoint).
      #
      # @param params [Hash] Search criteria (e.g. ggid: "zphsqa")
      # @return [Resource] The matching resource
      # @raise [ArgumentError] If no supported attribute is provided
      # @raise [NotFoundError] If no resource matches
      def fetch_by(params = {})
        @resource_class.fetch_by(params.merge(api_key: @api_key))
      end

      # Iterates through all pages of results.
      #
      # @param params [Hash] Query parameters for filtering
      # @yield [Resource] Each resource from all pages
      # @return [Enumerator] If no block given
      def auto_paging_each(params = {}, &block)
        @resource_class.auto_paging_each(params.merge(api_key: @api_key), &block)
      end

      # Collects all results from all pages.
      #
      # @param params [Hash] Query parameters for filtering
      # @return [Array<Resource>] All resources from all pages
      def list_all(params = {})
        @resource_class.list_all(params.merge(api_key: @api_key))
      end

      # Gets the event roster (Event-specific).
      #
      # @param event_id [String] The event ID
      # @param params [Hash] Query parameters
      # @return [Array<GolfGeniusObject>] Roster entries
      def roster(event_id, params = {})
        ensure_event_resource!
        @resource_class.roster(event_id, params.merge(api_key: @api_key))
      end

      # Gets the event rounds (Event-specific).
      #
      # @param event_id [String] The event ID
      # @param params [Hash] Query parameters
      # @return [Array<GolfGeniusObject>] Round entries
      def rounds(event_id, params = {})
        ensure_event_resource!
        @resource_class.rounds(event_id, params.merge(api_key: @api_key))
      end

      # Gets the event courses (Event-specific).
      #
      # @param event_id [String] The event ID
      # @param params [Hash] Query parameters
      # @return [Array<GolfGeniusObject>] Course entries
      def courses(event_id, params = {})
        ensure_event_resource!
        @resource_class.courses(event_id, params.merge(api_key: @api_key))
      end

      # Gets the event divisions (Event-specific).
      #
      # @param event_id [String] The event ID
      # @param params [Hash] Query parameters
      # @return [Array<Division>] Division entries
      def divisions(event_id, params = {})
        ensure_event_resource!
        @resource_class.divisions(event_id, params.merge(api_key: @api_key))
      end

      # Gets tournaments for a round (Event-specific).
      #
      # @param event_id [String] The event ID
      # @param round_id [String] The round ID
      # @param params [Hash] Query parameters
      # @return [Array<GolfGeniusObject>] Tournament entries
      def tournaments(event_id, round_id, params = {})
        ensure_event_resource!
        @resource_class.tournaments(event_id, round_id, params.merge(api_key: @api_key))
      end

      # Gets tee sheet and scores for a round (Event-specific).
      #
      # @param event_id [String] The event ID
      # @param round_id [String] The round ID
      # @param params [Hash] Query parameters (e.g. include_all_custom_fields)
      # @return [Array<TeeSheetGroup>] Pairing group entries
      def tee_sheet(event_id, round_id, params = {})
        ensure_event_resource!
        @resource_class.tee_sheet(event_id, round_id, params.merge(api_key: @api_key))
      end

      # Ensures this proxy points at the Event resource class.
      #
      # @raise [NoMethodError] When the resource does not support event-specific methods
      # @return [void]
      def ensure_event_resource!
        return if @resource_class == Event

        raise NoMethodError, "#{@resource_class.name} does not support this method"
      end
    end

    # Internal class to proxy Player-specific calls with the client's API key.
    #
    # @api private
    class PlayerProxy < ResourceProxy
      # Gets a player's event ids.
      #
      # @param player_id [String, Integer] Player id
      # @param params [Hash] Optional request params
      # @return [GolfGeniusObject]
      def events(player_id, params = {})
        @resource_class.events(player_id, params.merge(api_key: @api_key))
      end
    end
  end
end
