# frozen_string_literal: true

module GolfGenius
  module APIOperations
    # Provides functionality for accessing nested resources.
    # Extend this module in resource classes that have nested endpoints.
    #
    # @example
    #   class Event < Resource
    #     extend APIOperations::NestedResource
    #
    #     nested_resource :roster, path: "/events/%<parent_id>s/roster"
    #     nested_resource :rounds, path: "/events/%<parent_id>s/rounds"
    #   end
    #
    #   roster = Event.roster('event_123')
    #   rounds = Event.rounds('event_123')
    module NestedResource
      # Defines a nested resource accessor on the class.
      #
      # @param name [Symbol] The method name for accessing the nested resource
      # @param path [String] The path template with %<parent_id>s placeholder
      # @param returns [Symbol] The return type (:array or :object, default: :array)
      # @param resource_class [Class, nil] Optional class to construct results as
      # @param item_key [String, Symbol, nil] If the API wraps each item (e.g. { "member" => {...} }), key to unwrap
      # @param response_key [String, Symbol, nil] If the response is a hash (e.g. { "courses" => [...] }), array key
      # @param attribute_aliases [Hash, nil] Map of alias_key => api_key so API keys are exposed
      #   (e.g. photo_url: "photo")
      # @param inject_parent [Hash, nil] Merge parent context into each item (e.g. { event_id: :parent_id }
      #   so Round has event_id)
      # @param sort_by [Symbol, nil] Attribute to sort the array by (e.g. :index for rounds)
      # @param paginated [Boolean] If true, when :page is not in params, fetch all pages and return combined array
      #   (default: false)
      # @param page_size [Integer] API page size when paginated (e.g. 100 for roster); used to detect last page
      # @param client_filters [Hash, nil] Params that are not sent to the API; applied client-side after fetch.
      #   Keys are param names (e.g. +:waitlist+), values are the attribute name on each item (e.g. +:waitlist+)
      #   or a Proc +(item, value) -> bool+. Example: +client_filters: { waitlist: :waitlist }+ for roster
      #   (confirmed only: +waitlist: false+).
      #
      # @example Define a nested roster resource (API returns [ { "member" => {...} } ])
      #   nested_resource :roster, path: "/events/%<parent_id>s/roster", item_key: "member"
      #
      # @example Define a nested resource that returns a single object
      #   nested_resource :summary, path: "/events/%<parent_id>s/summary", returns: :object
      def nested_resource(name, path:, returns: :array, resource_class: nil, item_key: nil, response_key: nil,
                          attribute_aliases: nil, inject_parent: nil, sort_by: nil, paginated: false, page_size: 100,
                          client_filters: nil)
        client_filters = (client_filters || {}).freeze
        define_singleton_method(name) do |parent_id, params = {}|
          params = params.dup
          api_key = params.delete(:api_key)
          client_filter_values = {}
          client_filters.each_key { |k| client_filter_values[k] = params.delete(k) if params.key?(k) }
          resolved_path = format(path, parent_id: parent_id)

          fetch_page = lambda do |page_params|
            response = Request.execute(
              method: :get,
              path: resolved_path,
              params: page_params,
              api_key: api_key
            )
            unless returns == :array
              klass = resource_class || GolfGeniusObject
              return klass.construct_from(response, api_key: api_key)
            end
            data = Util.extract_data_array(response, response_key: response_key)
            klass = resource_class || GolfGeniusObject
            data.map do |item|
              attrs = item_key ? Util.unwrap_list_item(item, item_key: item_key) : item
              attrs = apply_attribute_aliases(attrs, attribute_aliases)
              attrs = inject_parent_attrs(attrs, parent_id, inject_parent)
              klass.construct_from(attrs, api_key: api_key)
            end
          end

          if returns == :array && paginated && !params.key?(:page)
            all_results = []
            page = 1
            loop do
              page_params = params.merge(page: page)
              page_result = fetch_page.call(page_params)
              break if page_result.empty?

              all_results.concat(page_result)
              break if page_result.length < page_size

              page += 1
            end
            unless client_filter_values.empty?
              all_results = apply_client_filters(all_results, client_filter_values, client_filters)
            end
            if sort_by
              all_results.sort_by { |obj| obj.respond_to?(sort_by) ? (obj.send(sort_by) || 0) : 0 }
            else
              all_results
            end
          else
            result = fetch_page.call(params)
            if result.is_a?(Array) && !client_filter_values.empty?
              result = apply_client_filters(result, client_filter_values, client_filters)
            end
            if sort_by && result.is_a?(Array)
              result = result.sort_by { |obj| obj.respond_to?(sort_by) ? (obj.send(sort_by) || 0) : 0 }
            end
            result
          end
        end

        define_method(name) do |params = {}|
          params = params.dup
          params[:api_key] ||= (respond_to?(:api_key, true) ? send(:api_key) : nil)
          self.class.public_send(name, id, params)
        end
      end

      # Defines a deeply nested resource accessor (e.g., events/:id/rounds/:round_id/tournaments).
      # Signature: name(event_id, round_id, params = {}, api_key: nil) — params is optional third positional arg.
      #
      # @param name [Symbol] The method name for accessing the nested resource
      # @param path [String] The path template with %<event_id>s, %<round_id>s etc. placeholders
      # @param parent_ids [Array<Symbol>] The names of the parent ID parameters in order
      # @param returns [Symbol] The return type (:array or :object, default: :array)
      # @param resource_class [Class, nil] Optional class to construct results as
      # @param item_key [String, Symbol, nil] If the API wraps each item, the key to unwrap
      # @param response_key [String, Symbol, nil] If the response is a hash, the key for the array
      # @param paginated [Boolean] If true, when :page is not in params, fetch all pages (default: false)
      # @param page_size [Integer] API page size when paginated (default: 100)
      #
      # @example Define a deeply nested tournaments resource
      #   deep_nested_resource :tournaments,
      #     path: "/events/%<event_id>s/rounds/%<round_id>s/tournaments",
      #     parent_ids: [:event_id, :round_id]
      def deep_nested_resource(name, path:, parent_ids:, returns: :array, resource_class: nil, item_key: nil,
                               response_key: nil, paginated: false, page_size: 100)
        define_singleton_method(name) do |*args|
          extra = args[parent_ids.length]
          params = args.length > parent_ids.length && extra.is_a?(Hash) ? extra.dup : {}
          api_key = params.delete(:api_key)
          ids = args[0, parent_ids.length]
          ids = resolve_parent_ids(ids)
          if ids.length < parent_ids.length
            raise ArgumentError, "Expected #{parent_ids.length} IDs (#{parent_ids.join(", ")}), got #{args.length}"
          end

          path_params = parent_ids.zip(ids).to_h
          resolved_path = format(path, path_params)

          fetch_page = lambda do |page_params|
            response = Request.execute(
              method: :get,
              path: resolved_path,
              params: page_params,
              api_key: api_key
            )
            unless returns == :array
              klass = resource_class || GolfGeniusObject
              return klass.construct_from(response, api_key: api_key)
            end
            data = Util.extract_data_array(response, response_key: response_key)
            klass = resource_class || GolfGeniusObject
            data.map do |item|
              attrs = item_key ? Util.unwrap_list_item(item, item_key: item_key) : item
              klass.construct_from(attrs, api_key: api_key)
            end
          end

          if returns == :array && paginated && !params.key?(:page)
            all_results = []
            page = 1
            loop do
              page_params = params.merge(page: page)
              page_result = fetch_page.call(page_params)
              break if page_result.empty?

              all_results.concat(page_result)
              break if page_result.length < page_size

              page += 1
            end
            all_results
          else
            fetch_page.call(params)
          end
        end

        # Instance method: event.tournaments(round_id_or_round, params = {}) or event.tournaments(round: round_obj).
        define_method(name) do |*args|
          params = args.last.is_a?(Hash) ? args.pop.dup : {}
          params[:api_key] ||= (respond_to?(:api_key, true) ? send(:api_key) : nil)
          # Allow last parent(s) as keywords, e.g. round: round_obj for parent_ids [:event_id, :round_id]
          other_ids = args.dup
          (parent_ids.length - 1).times do |i|
            param_key = parent_ids[i + 1].to_s.sub(/_id$/, "").to_sym
            other_ids[i] = params.delete(param_key) if params.key?(param_key)
          end
          required_count = parent_ids.length - 1
          if other_ids.length < required_count
            raise ArgumentError,
                  "#{name} requires #{required_count} argument(s) " \
                  "(#{parent_ids[1..].join(", ")}), got #{other_ids.length}"
          end
          resolved = self.class.resolve_parent_ids(other_ids)
          self.class.public_send(name, id, *resolved, params)
        end
      end

      # Resolves parent IDs: objects that respond to :id become .id, others pass through.
      def resolve_parent_ids(ids)
        Array(ids).map { |id_or_obj| id_or_obj.respond_to?(:id) ? id_or_obj.id : id_or_obj }
      end

      # Applies client-side filters to an array. Params in client_filters are not sent to the API;
      # after fetch, the array is filtered by each (param_key, attr_or_proc) where a value was passed.
      # attr_or_proc is an attribute name (Symbol): keep items where item.send(attr) == value.
      # attr_or_proc is a Proc: keep items where proc.call(item, value) is truthy.
      def apply_client_filters(array, client_filter_values, client_filters)
        return array if array.nil? || array.empty? || client_filter_values.empty?

        client_filters.each do |param_key, attr_or_proc|
          value = client_filter_values[param_key]
          next if value.nil?

          array = if attr_or_proc.is_a?(Proc)
                    array.select { |item| attr_or_proc.call(item, value) }
                  else
                    attr = attr_or_proc.to_sym
                    array.select { |item| item.respond_to?(attr) && item.send(attr) == value }
                  end
        end
        array
      end

      # Applies attribute aliases so API keys (e.g. "photo") are exposed as Ruby-friendly names (e.g. photo_url).
      def apply_attribute_aliases(attrs, attribute_aliases)
        return attrs if attribute_aliases.nil? || attribute_aliases.empty?

        attrs = attrs.dup
        attribute_aliases.each do |alias_key, api_key|
          val = attrs[api_key] || attrs[api_key.to_s]
          attrs[alias_key] = val
        end
        attrs
      end

      # Merges parent context into each item so children can navigate (e.g. Round gets event_id for .tournaments).
      def inject_parent_attrs(attrs, parent_id, inject_parent)
        return attrs if inject_parent.nil? || inject_parent.empty?

        attrs = attrs.dup
        inject_parent.each_key { |attr_key| attrs[attr_key] = parent_id }
        attrs
      end
    end
  end
end
