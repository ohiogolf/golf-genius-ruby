# frozen_string_literal: true

module GolfGenius
  # Base error class for all Golf Genius errors
  class GolfGeniusError < StandardError
    attr_reader :http_status, :http_body, :http_headers, :request_id

    def initialize(message = nil, http_status: nil, http_body: nil, http_headers: nil, request_id: nil)
      @http_status = http_status
      @http_body = http_body
      @http_headers = http_headers || {}
      @request_id = request_id
      super(message)
    end

    def to_s
      status_string = @http_status.nil? ? "" : "(Status #{@http_status}) "
      id_string = @request_id.nil? ? "" : "(Request #{@request_id}) "
      "#{status_string}#{id_string}#{super}"
    end
  end

  # Raised when the API key is missing or invalid
  class AuthenticationError < GolfGeniusError; end

  # Raised when the requested resource is not found
  class NotFoundError < GolfGeniusError; end

  # Raised when the request parameters are invalid
  class ValidationError < GolfGeniusError; end

  # Raised when rate limit is exceeded
  class RateLimitError < GolfGeniusError; end

  # Raised on 5xx server errors
  class ServerError < GolfGeniusError; end

  # Raised when the API returns an unexpected response
  class APIError < GolfGeniusError; end

  # Raised when a network error occurs
  class ConnectionError < GolfGeniusError; end

  # Raised when the API key is not configured
  class ConfigurationError < GolfGeniusError; end
end
