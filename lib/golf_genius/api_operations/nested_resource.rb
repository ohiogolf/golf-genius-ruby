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
    #     nested_resource :roster, path: "/events/%{parent_id}/roster"
    #     nested_resource :rounds, path: "/events/%{parent_id}/rounds"
    #   end
    #
    #   roster = Event.roster('event_123')
    #   rounds = Event.rounds('event_123')
    module NestedResource
      # Defines a nested resource accessor on the class.
      #
      # @param name [Symbol] The method name for accessing the nested resource
      # @param path [String] The path template with %{parent_id} placeholder
      # @param returns [Symbol] The return type (:array or :object, default: :array)
      # @param resource_class [Class, nil] Optional class to construct results as
      #
      # @example Define a nested roster resource
      #   nested_resource :roster, path: "/events/%{parent_id}/roster"
      #
      # @example Define a nested resource that returns a single object
      #   nested_resource :summary, path: "/events/%{parent_id}/summary", returns: :object
      def nested_resource(name, path:, returns: :array, resource_class: nil)
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
            data = Util.extract_data_array(response)
            klass = resource_class || GolfGeniusObject
            data.map { |item| klass.construct_from(item, api_key: api_key) }
          else
            klass = resource_class || GolfGeniusObject
            klass.construct_from(response, api_key: api_key)
          end
        end
      end

      # Defines a deeply nested resource accessor (e.g., events/:id/rounds/:round_id/tournaments).
      #
      # @param name [Symbol] The method name for accessing the nested resource
      # @param path [String] The path template with multiple placeholders
      # @param parent_ids [Array<Symbol>] The names of the parent ID parameters in order
      # @param returns [Symbol] The return type (:array or :object, default: :array)
      # @param resource_class [Class, nil] Optional class to construct results as
      #
      # @example Define a deeply nested tournaments resource
      #   deep_nested_resource :tournaments,
      #     path: "/events/%{event_id}/rounds/%{round_id}/tournaments",
      #     parent_ids: [:event_id, :round_id]
      def deep_nested_resource(name, path:, parent_ids:, returns: :array, resource_class: nil)
        define_singleton_method(name) do |*ids, **options|
          if ids.length != parent_ids.length
            raise ArgumentError, "Expected #{parent_ids.length} IDs (#{parent_ids.join(', ')}), got #{ids.length}"
          end

          params = options.fetch(:params, {}).dup
          api_key = params.delete(:api_key) || options[:api_key]

          # Build the path substitution hash
          path_params = parent_ids.zip(ids).to_h
          resolved_path = format(path, path_params)

          response = Request.execute(
            method: :get,
            path: resolved_path,
            params: params,
            api_key: api_key
          )

          if returns == :array
            data = Util.extract_data_array(response)
            klass = resource_class || GolfGeniusObject
            data.map { |item| klass.construct_from(item, api_key: api_key) }
          else
            klass = resource_class || GolfGeniusObject
            klass.construct_from(response, api_key: api_key)
          end
        end
      end
    end
  end
end
