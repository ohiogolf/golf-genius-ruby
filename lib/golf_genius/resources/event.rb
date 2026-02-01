# frozen_string_literal: true

module GolfGenius
  # Represents a Golf Genius event.
  # Business: The thing you're actually running—an outing, championship, league, or trip. It has the roster
  # (who's in), rounds (which days), courses (where), and drives registration and play.
  #
  # List parameters (all optional; pass to +list+, +list_all+, +auto_paging_each+, +fetch+):
  # * +:directory+ or +:directory_id+ — Filter to events in this directory (object or id).
  # * +:season+ or +:season_id+ — Filter to events in this season (object or id).
  # * +:category+ or +:category_id+ — Filter to events in this category (object or id).
  # * +:archived+ — +true+ = archived events only; +false+ or omitted = non-archived only (API default).
  # * +:page+ — Request a single page (stops auto-paging); omit to fetch all pages.
  # * +:api_key+ — Override the configured API key.
  #
  # Roster parameters (for +roster(event_id, ...)+): +:page+ (single page), +:photo+ (+true+ to include
  # profile picture URLs; default is no photos), +:waitlist+ (+false+ = confirmed only, +true+ = waitlisted only;
  # filtered client-side; API ignores this param).
  #
  # @example List events with filters
  #   events = GolfGenius::Event.list(
  #     directory: dir,
  #     season: season,
  #     archived: false
  #   )
  #
  # @example Fetch a specific event by id or ggid
  #   event = GolfGenius::Event.fetch(171716)
  #   event = GolfGenius::Event.fetch_by(ggid: 'zphsqa')  # by ggid
  #   event = GolfGenius::Event.fetch(171716, season_id: 'season_123', max_pages: 10)
  #   event = GolfGenius::Event.fetch(171716, archived: true)  # archived only
  #
  # @example Get event roster (class or instance)
  #   roster = GolfGenius::Event.roster('event_123', photo: true)
  #   roster = event.roster(photo: true, waitlist: false)  # confirmed only (filtered client-side)
  #   roster.each { |player| puts player.name; puts player.photo_url }
  #
  # @example Get event rounds, divisions, tee sheet, and tournaments (class or instance)
  #   rounds = GolfGenius::Event.rounds('event_123')
  #   divisions = event.divisions
  #   tee_sheet = event.tee_sheet('round_456')
  #   round = event.rounds.first
  #   tournaments = round.tournaments  # Round has event_id when from event.rounds
  #   tournaments = event.tournaments('round_456')
  #   tournaments = event.tournaments(round)        # pass Round object
  #   tournaments = event.tournaments(round: round)  # or as keyword
  #
  # @example Iterate through all events
  #   GolfGenius::Event.auto_paging_each(season_id: 'season_123') do |event|
  #     puts event.name
  #   end
  #
  # @see https://www.golfgenius.com/api/v2/docs Golf Genius API Documentation
  # rubocop:disable Metrics/ClassLength
  class Event < Resource
    # API endpoint path for events
    RESOURCE_PATH = "/events"

    extend APIOperations::List
    extend APIOperations::Fetch
    extend APIOperations::NestedResource

    # Match fetch by id or ggid (API returns both)
    fetch_match_on :id, :ggid

    # Fetch a single event by id. When :archived is not specified, try non-archived
    # first, then fall back to archived events before raising not found. If :archived
    # is explicitly set (true or false), only that scope is searched. The same rules
    # apply to +fetch_by+ (e.g., by ggid).
    def self.fetch(id, params = {})
      params = params.dup
      return super if archived_param?(params)

      begin
        super
      rescue NotFoundError
        super(id, params.merge(archived: true))
      end
    end

    # Fetch a single event by ggid (or id) using list pagination with archived fallback.
    def self.fetch_by(params = {})
      params = params.dup
      max_pages = params.delete(:max_pages) || 20
      field, value, list_params, archived_explicit = parse_fetch_by_params(params)

      return fetch(value, list_params.merge(max_pages: max_pages)) if field == :id
      return fetch_by_list(field, value, list_params, max_pages) if archived_explicit

      begin
        fetch_by_list(field, value, list_params, max_pages)
      rescue NotFoundError
        fetch_by_list(field, value, list_params.merge(archived: true), max_pages)
      end
    end

    def self.archived_param?(params)
      params.key?(:archived) || params.key?("archived")
    end
    private_class_method :archived_param?

    def self.parse_fetch_by_params(params)
      params = params.dup
      params.delete(:api_key)
      params.delete("api_key")

      field, value, params = extract_fetch_by_field(params)
      archived_explicit = archived_param?(params)
      validate_fetch_by_params!(params)

      [field, value, params, archived_explicit]
    end
    private_class_method :parse_fetch_by_params

    def self.extract_fetch_by_field(params)
      match_keys = params.keys.map(&:to_sym)
      fetch_fields = fetch_match_fields
      search_keys = match_keys & fetch_fields
      raise ArgumentError, "fetch_by requires one of: #{fetch_fields.join(", ")}" if search_keys.empty?
      raise ArgumentError, "fetch_by accepts only one attribute" if search_keys.length > 1

      field = search_keys.first
      value = params.key?(field) ? params.delete(field) : params.delete(field.to_s)
      raise ArgumentError, "#{field} is required" if value.nil? || value.to_s.empty?

      [field, value, params]
    end
    private_class_method :extract_fetch_by_field

    def self.validate_fetch_by_params!(params)
      remaining_keys = params.keys.map(&:to_sym) - [:archived]
      return if remaining_keys.empty?

      fetch_fields = fetch_match_fields
      raise ArgumentError, "Only #{fetch_fields.join(", ")} are supported"
    end
    private_class_method :validate_fetch_by_params!

    def self.fetch_by_list(field, value, list_params, max_pages)
      value_str = value.to_s
      page = 1
      while page <= max_pages
        results = list(list_params.merge(page: page))
        break if results.empty?

        found = results.find { |item| match_fetch_on?(item, [field], value_str) }
        return found if found

        break if results.length < expected_page_size(list_params)

        page += 1
      end

      raise NotFoundError, "Resource not found: #{field}=#{value_str}"
    end
    private_class_method :fetch_by_list

    # Nested resource: Event roster (API returns [ { "member" => {...} } ]).
    # With photo: true, the API returns "photo" URL; we expose it as photo_url.
    # Paginated: when :page is omitted, fetches all pages (API returns 100 per page).
    # client_filters: :waitlist is not sent to the API; filtered client-side (waitlist: false = confirmed only).
    nested_resource :roster, path: "/events/%<parent_id>s/roster", item_key: "member",
                             attribute_aliases: { photo_url: "photo" },
                             resource_class: RosterMember,
                             paginated: true,
                             page_size: 100,
                             client_filters: { waitlist: :waitlist }

    # Nested resource: Event rounds (API returns [ { "round" => {...} } ]).
    # Injects event_id so Round#tournaments works. Always ordered by index. Paginated when :page omitted.
    nested_resource :rounds, path: "/events/%<parent_id>s/rounds", item_key: "round",
                             resource_class: Round,
                             inject_parent: { event_id: :parent_id },
                             sort_by: :index,
                             paginated: true,
                             page_size: 100

    # Nested resource: Event courses/tees (API returns { "courses" => [...] }). Paginated when :page omitted.
    nested_resource :courses,
                    path: "/events/%<parent_id>s/courses",
                    response_key: "courses",
                    resource_class: Course,
                    paginated: true,
                    page_size: 100

    # Nested resource: Event divisions (API returns [ { "division" => {...} } ]). External divisions only.
    nested_resource :divisions,
                    path: "/events/%<parent_id>s/divisions",
                    item_key: "division",
                    resource_class: Division

    # Deeply nested resource: Tournaments for a specific round. Paginated when :page omitted.
    deep_nested_resource :tournaments,
                         path: "/events/%<event_id>s/rounds/%<round_id>s/tournaments",
                         parent_ids: %i[event_id round_id],
                         item_key: "event",
                         resource_class: Tournament,
                         paginated: true,
                         page_size: 100

    # Deeply nested resource: Tee sheet and scores for a specific round.
    # Returns an array of pairing groups (API returns [ { "pairing_group" => {...} } ]).
    deep_nested_resource :tee_sheet,
                         path: "/events/%<event_id>s/rounds/%<round_id>s/tee_sheet",
                         parent_ids: %i[event_id round_id],
                         item_key: "pairing_group",
                         resource_class: TeeSheetGroup,
                         paginated: true,
                         page_size: 100

    # API returns 100 events per page
    def self.expected_page_size(params)
      params[:per_page] || params[:limit] || 100
    end

    # Returns the event's season as a Season object (from embedded API response).
    #
    # @return [Season, nil]
    def season
      typed_association(:season, Season)
    end

    # Returns the event's category as a Category object (from embedded API response).
    #
    # @return [Category, nil]
    def category
      typed_association(:category, Category)
    end

    # Returns the event's directories as an array of Directory objects (from embedded API response).
    # API returns [ { "directory" => {...} } ]; we unwrap and type as Directory.
    #
    # @return [Array<Directory>]
    def directories
      raw = @attributes[:directories]
      return [] if raw.nil?

      normalize_directories(raw)
    end

    private

    # Returns a typed association for an embedded attribute.
    #
    # @param attr_key [Symbol] The attribute key to access
    # @param klass [Class] The class to construct if needed
    # @return [Object, nil] Instance of +klass+ or nil
    def typed_association(attr_key, klass)
      raw = @attributes[attr_key]
      return nil if raw.nil?
      return raw if raw.is_a?(klass)

      attrs = raw.respond_to?(:to_h) ? raw.to_h : raw
      return nil unless attrs.is_a?(Hash) && !attrs.empty?

      klass.construct_from(attrs, api_key: api_key)
    end

    # Normalizes directory list data into Directory objects.
    #
    # @param raw [Array, Hash, Object] Raw directories data
    # @return [Array<Directory>] Array of directories
    def normalize_directories(raw)
      arr = raw.is_a?(Array) ? raw : Array(raw)
      arr.filter_map { |item| normalize_directory_item(item) }
    end

    # Normalizes a single directory list item.
    #
    # @param item [Hash, Directory, nil] Raw list item
    # @return [Directory, nil] Directory instance or nil when empty
    def normalize_directory_item(item)
      return if item.nil?
      return item if item.is_a?(Directory)

      attrs = Util.unwrap_list_item(item.respond_to?(:to_h) ? item.to_h : item, item_key: "directory")
      return unless attrs.is_a?(Hash) && !attrs.empty?

      Directory.construct_from(attrs, api_key: api_key)
    end
  end
  # rubocop:enable Metrics/ClassLength
end
