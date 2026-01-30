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
      #
      # @example Define a nested roster resource (API returns [ { "member" => {...} } ])
      #   nested_resource :roster, path: "/events/%<parent_id>s/roster", item_key: "member"
      #
      # @example Define a nested resource that returns a single object
      #   nested_resource :summary, path: "/events/%<parent_id>s/summary", returns: :object
      def nested_resource(name, path:, returns: :array, resource_class: nil, item_key: nil, response_key: nil)
        define_singleton_method(name) do |parent_id, params = {}|
          params = params.dup
          api_key = params.delete(:api_key)

          resolved_path = format(path, parent_id: parent_id)

          response = Request.execute(
            method: :get,
            path: resolved_path,
            params: params,
            api_key: api_key
          )

          if returns == :array
            data = Util.extract_data_array(response, response_key: response_key)
            klass = resource_class || GolfGeniusObject
            data.map do |item|
              attrs = item_key ? Util.unwrap_list_item(item, item_key: item_key) : item
              klass.construct_from(attrs, api_key: api_key)
            end
          else
            klass = resource_class || GolfGeniusObject
            klass.construct_from(response, api_key: api_key)
          end
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
      #
      # @example Define a deeply nested tournaments resource
      #   deep_nested_resource :tournaments,
      #     path: "/events/%<event_id>s/rounds/%<round_id>s/tournaments",
      #     parent_ids: [:event_id, :round_id]
      def deep_nested_resource(name, path:, parent_ids:, returns: :array, resource_class: nil, item_key: nil,
                               response_key: nil)
        define_singleton_method(name) do |*args|
          if args.length < parent_ids.length
            raise ArgumentError, "Expected #{parent_ids.length} IDs (#{parent_ids.join(", ")}), got #{args.length}"
          end

          ids = args[0, parent_ids.length]
          extra = args[parent_ids.length]
          params = args.length > parent_ids.length && extra.is_a?(Hash) ? extra.dup : {}
          api_key = params.delete(:api_key)

          path_params = parent_ids.zip(ids).to_h
          resolved_path = format(path, path_params)

          response = Request.execute(
            method: :get,
            path: resolved_path,
            params: params,
            api_key: api_key
          )

          if returns == :array
            data = Util.extract_data_array(response, response_key: response_key)
            klass = resource_class || GolfGeniusObject
            data.map do |item|
              attrs = item_key ? Util.unwrap_list_item(item, item_key: item_key) : item
              klass.construct_from(attrs, api_key: api_key)
            end
          else
            klass = resource_class || GolfGeniusObject
            klass.construct_from(response, api_key: api_key)
          end
        end
      end
    end
  end
end
