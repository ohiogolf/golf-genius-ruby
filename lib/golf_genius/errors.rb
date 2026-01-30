# frozen_string_literal: true

module GolfGenius
  # Base error class for all Golf Genius errors.
  # All errors raised by this gem inherit from this class.
  #
  # @example Catching all Golf Genius errors
  #   begin
  #     event = GolfGenius::Event.fetch('invalid')
  #   rescue GolfGenius::GolfGeniusError => e
  #     puts "Error: #{e.message}"
  #     puts "Status: #{e.http_status}"
  #   end
  class GolfGeniusError < StandardError
    # @return [Integer, nil] The HTTP status code
    attr_reader :http_status

    # @return [String, Hash, nil] The HTTP response body
    attr_reader :http_body

    # @return [Hash] The HTTP response headers
    attr_reader :http_headers

    # @return [String, nil] The request ID for debugging
    attr_reader :request_id

    # Creates a new GolfGeniusError.
    #
    # @param message [String, nil] The error message
    # @param http_status [Integer, nil] The HTTP status code
    # @param http_body [String, Hash, nil] The HTTP response body
    # @param http_headers [Hash, nil] The HTTP response headers
    # @param request_id [String, nil] The request ID
    def initialize(message = nil, http_status: nil, http_body: nil, http_headers: nil, request_id: nil)
      @http_status = http_status
      @http_body = http_body
      @http_headers = http_headers || {}
      @request_id = request_id
      super(message)
    end

    # Returns a formatted error message including status and request ID.
    #
    # @return [String] The formatted error message
    def to_s
      status_string = @http_status.nil? ? "" : "(Status #{@http_status}) "
      id_string = @request_id.nil? ? "" : "(Request #{@request_id}) "
      "#{status_string}#{id_string}#{super}"
    end
  end

  # Raised when the API key is missing or invalid.
  # Corresponds to HTTP 401 and 403 responses.
  #
  # @example
  #   begin
  #     GolfGenius::Season.list
  #   rescue GolfGenius::AuthenticationError => e
  #     puts "Invalid API key: #{e.message}"
  #   end
  class AuthenticationError < GolfGeniusError; end

  # Raised when the requested resource is not found.
  # Corresponds to HTTP 404 responses.
  #
  # @example
  #   begin
  #     GolfGenius::Event.fetch('nonexistent')
  #   rescue GolfGenius::NotFoundError => e
  #     puts "Event not found: #{e.message}"
  #   end
  class NotFoundError < GolfGeniusError; end

  # Raised when the request parameters are invalid.
  # Corresponds to HTTP 422 responses.
  #
  # @example
  #   begin
  #     GolfGenius::Event.list(invalid_param: 'value')
  #   rescue GolfGenius::ValidationError => e
  #     puts "Invalid request: #{e.message}"
  #   end
  class ValidationError < GolfGeniusError; end

  # Raised when rate limit is exceeded.
  # Corresponds to HTTP 429 responses.
  #
  # @example
  #   begin
  #     GolfGenius::Event.list
  #   rescue GolfGenius::RateLimitError => e
  #     puts "Rate limited, retry after: #{e.http_headers['Retry-After']}"
  #   end
  class RateLimitError < GolfGeniusError; end

  # Raised on 5xx server errors.
  # Indicates a problem on the Golf Genius server side.
  #
  # @example
  #   begin
  #     GolfGenius::Event.list
  #   rescue GolfGenius::ServerError => e
  #     puts "Server error: #{e.message}"
  #   end
  class ServerError < GolfGeniusError; end

  # Raised when the API returns an unexpected response.
  # Used for error responses that don't fit other categories.
  class APIError < GolfGeniusError; end

  # Raised when a network error occurs.
  # Includes timeouts, connection failures, and other network issues.
  #
  # @example
  #   begin
  #     GolfGenius::Event.list
  #   rescue GolfGenius::ConnectionError => e
  #     puts "Network error: #{e.message}"
  #   end
  class ConnectionError < GolfGeniusError; end

  # Raised when the API key is not configured.
  # Indicates a configuration problem rather than an API error.
  #
  # @example
  #   begin
  #     GolfGenius::Event.list  # without setting api_key
  #   rescue GolfGenius::ConfigurationError => e
  #     puts "Please configure your API key"
  #   end
  class ConfigurationError < GolfGeniusError; end
end
