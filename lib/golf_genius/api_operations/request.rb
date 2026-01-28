# frozen_string_literal: true

require "faraday"
require "faraday/retry"
require "json"

module GolfGenius
  module APIOperations
    module Request
      def self.execute(method:, path:, params: {}, api_key: nil)
        api_key ||= GolfGenius.api_key
        raise ConfigurationError, "No API key provided. Set GolfGenius.api_key or pass api_key option." unless api_key

        # Build URL with API key in path
        url = "#{GolfGenius.base_url}/api_v2/#{api_key}#{path}"

        Util.log(:info, "GolfGenius API Request: #{method.to_s.upcase} #{url}")
        Util.log(:debug, "Request params: #{params.inspect}") unless params.empty?

        begin
          response = connection.send(method) do |req|
            req.url url
            req.params = params if method == :get && !params.empty?
            req.body = params.to_json if [:post, :put, :patch].include?(method) && !params.empty?
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

      def self.connection
        @connection ||= Faraday.new do |conn|
          conn.request :json
          conn.response :json, content_type: /\bjson$/
          conn.request :retry, {
            max: 3,
            interval: 0.5,
            interval_randomness: 0.5,
            backoff_factor: 2,
            exceptions: [Faraday::TimeoutError, Faraday::ConnectionFailed],
          }
          conn.options.timeout = GolfGenius.configuration.read_timeout
          conn.options.open_timeout = GolfGenius.configuration.open_timeout
          conn.adapter Faraday.default_adapter
        end
      end

      def self.handle_response(response)
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

      def self.error_message(response)
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
