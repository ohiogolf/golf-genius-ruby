# frozen_string_literal: true

module GolfGenius
  class Client
    attr_reader :api_key

    def initialize(api_key: nil)
      @api_key = api_key || GolfGenius.api_key
      raise ConfigurationError, "API key is required" unless @api_key
    end

    def seasons
      @seasons ||= ResourceProxy.new(Season, @api_key)
    end

    def categories
      @categories ||= ResourceProxy.new(Category, @api_key)
    end

    def directories
      @directories ||= ResourceProxy.new(Directory, @api_key)
    end

    def events
      @events ||= ResourceProxy.new(Event, @api_key)
    end

    # Internal class to proxy resource calls with client's API key
    class ResourceProxy
      def initialize(resource_class, api_key)
        @resource_class = resource_class
        @api_key = api_key
      end

      def list(params = {})
        @resource_class.list(params, api_key: @api_key)
      end

      def retrieve(id, params = {})
        @resource_class.retrieve(id, params, api_key: @api_key)
      end

      def method_missing(method_name, *args, **kwargs)
        if @resource_class.respond_to?(method_name)
          @resource_class.send(method_name, *args, **kwargs.merge(api_key: @api_key))
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        @resource_class.respond_to?(method_name) || super
      end
    end
  end
end
