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
          query = nil
          if method == :get && !params.empty?
            query = params.map do |k, v|
              "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}"
            end.join("&")
          end

          # Log URL never contains the real API key
          log_url = "#{GolfGenius.base_url}/api_v2/[REDACTED-API-KEY]#{path}"
          log_url = "#{log_url}?#{query}" if query
          Util.log(:info, "GolfGenius API Request: #{method.to_s.upcase} #{log_url}")
          Util.log(:debug, "Request body: #{params.to_json}") if %i[post put patch].include?(method) && !params.empty?

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

        # Returns a cached Faraday connection, rebuilding when configuration changes.
        #
        # @return [Faraday::Connection] The configured Faraday connection
        def connection
          current_version = GolfGenius.configuration.version

          # Rebuild connection if configuration has changed
          if @connection.nil? || @connection_config_version != current_version
            @connection_config_version = current_version
            @connection = build_connection
          end

          @connection
        end

        # Builds a Faraday connection with retry and JSON middleware.
        #
        # @return [Faraday::Connection] The configured Faraday connection
        def build_connection
          config = GolfGenius.configuration

          Faraday.new do |conn|
            conn.request :json
            conn.response :json, content_type: /\bjson$/
            conn.request :retry, {
              max: config.retry_max,
              interval: config.retry_interval,
              interval_randomness: 0.5,
              backoff_factor: 2,
              exceptions: [Faraday::TimeoutError, Faraday::ConnectionFailed],
            }
            conn.options.timeout = config.read_timeout
            conn.options.open_timeout = config.open_timeout
            conn.adapter Faraday.default_adapter
          end
        end

        # Handles an HTTP response and raises the appropriate error type.
        #
        # @param response [Faraday::Response] The response to process
        # @return [Hash, Array] Parsed JSON body for successful responses
        # @raise [AuthenticationError, NotFoundError, ValidationError, RateLimitError, ServerError, APIError]
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

        # Extracts an error message from a response body.
        #
        # @param response [Faraday::Response] The response to inspect
        # @return [String] A human-friendly error message
        def error_message(response)
          body = response.body
          if body.is_a?(Hash) && body["error"]
            body["error"]
          elsif body.is_a?(Hash) && body["message"]
            body["message"]
          elsif body.is_a?(String)
            # Avoid dumping HTML (e.g. Golf Genius 404 page) into the exception message
            if body.strip.downcase.start_with?("<!doctype") || body.strip.downcase.start_with?("<html")
              case response.status
              when 404 then "Resource not found"
              else "API request failed with status #{response.status}"
              end
            else
              body
            end
          else
            "API request failed with status #{response.status}"
          end
        end
      end
    end
  end
end
