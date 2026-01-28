# frozen_string_literal: true

require "faraday"
require "faraday/retry"
require "json"

module GolfGenius
  module APIOperations
    # Handles HTTP request execution for the Golf Genius API.
    #
    # @see https://www.golfgenius.com/api/v2/docs Golf Genius API Documentation
    module Request
      class << self
        # Executes an HTTP request to the Golf Genius API.
        #
        # @param method [Symbol] HTTP method (:get, :post, :put, :patch, :delete)
        # @param path [String] API endpoint path (without base URL or API key)
        # @param params [Hash] Request parameters (query params for GET, body for POST/PUT/PATCH)
        # @param api_key [String, nil] API key (uses configured key if not provided)
        #
        # @return [Hash, Array] Parsed JSON response body
        #
        # @raise [ConfigurationError] If no API key is available
        # @raise [AuthenticationError] For 401/403 responses
        # @raise [NotFoundError] For 404 responses
        # @raise [ValidationError] For 422 responses
        # @raise [RateLimitError] For 429 responses
        # @raise [ServerError] For 5xx responses
        # @raise [ConnectionError] For network errors
        # @raise [APIError] For other error responses
        def execute(method:, path:, params: {}, api_key: nil)
          api_key ||= GolfGenius.api_key
          unless api_key
            raise ConfigurationError,
                  "No API key provided. Set GolfGenius.api_key or pass api_key parameter."
          end

          # Build URL with API key in path
          url = "#{GolfGenius.base_url}/api_v2/#{api_key}#{path}"

          Util.log(:info, "GolfGenius API Request: #{method.to_s.upcase} #{url}")
          Util.log(:debug, "Request params: #{params.inspect}") unless params.empty?

          begin
            response = connection.send(method) do |req|
              req.url url
              req.params = params if method == :get && !params.empty?
              req.body = params.to_json if %i[post put patch].include?(method) && !params.empty?
            end

            handle_response(response)
          rescue Faraday::TimeoutError => e
            raise ConnectionError.new("Request timeout: #{e.message}", http_status: nil)
          rescue Faraday::ConnectionFailed => e
            raise ConnectionError.new("Connection failed: #{e.message}", http_status: nil)
          rescue Faraday::Error => e
            raise ConnectionError.new("Network error: #{e.message}", http_status: nil)
          end
        end

        # Resets the cached connection.
        # Called automatically when configuration changes.
        #
        # @return [void]
        # @api private
        def reset_connection!
          @connection = nil
          @connection_config_version = nil
        end

        private

        def connection
          current_version = GolfGenius.configuration.version

          # Rebuild connection if configuration has changed
          if @connection.nil? || @connection_config_version != current_version
            @connection_config_version = current_version
            @connection = build_connection
          end

          @connection
        end

        def build_connection
          config = GolfGenius.configuration

          Faraday.new do |conn|
            conn.request :json
            conn.response :json, content_type: /\bjson$/
            conn.request :retry, {
              max: 3,
              interval: 0.5,
              interval_randomness: 0.5,
              backoff_factor: 2,
              exceptions: [Faraday::TimeoutError, Faraday::ConnectionFailed],
            }
            conn.options.timeout = config.read_timeout
            conn.options.open_timeout = config.open_timeout
            conn.adapter Faraday.default_adapter
          end
        end

        def handle_response(response)
          Util.log(:info, "GolfGenius API Response: #{response.status}")
          Util.log(:debug, "Response body: #{response.body.inspect}")

          case response.status
          when 200..299
            response.body
          when 401, 403
            raise AuthenticationError.new(
              error_message(response),
              http_status: response.status,
              http_body: response.body,
              http_headers: response.headers
            )
          when 404
            raise NotFoundError.new(
              error_message(response),
              http_status: response.status,
              http_body: response.body,
              http_headers: response.headers
            )
          when 422
            raise ValidationError.new(
              error_message(response),
              http_status: response.status,
              http_body: response.body,
              http_headers: response.headers
            )
          when 429
            raise RateLimitError.new(
              error_message(response),
              http_status: response.status,
              http_body: response.body,
              http_headers: response.headers
            )
          when 500..599
            raise ServerError.new(
              error_message(response),
              http_status: response.status,
              http_body: response.body,
              http_headers: response.headers
            )
          else
            raise APIError.new(
              error_message(response),
              http_status: response.status,
              http_body: response.body,
              http_headers: response.headers
            )
          end
        end

        def error_message(response)
          body = response.body
          if body.is_a?(Hash) && body["error"]
            body["error"]
          elsif body.is_a?(Hash) && body["message"]
            body["message"]
          elsif body.is_a?(String)
            body
          else
            "API request failed with status #{response.status}"
          end
        end
      end
    end
  end
end
