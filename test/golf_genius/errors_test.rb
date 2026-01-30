# frozen_string_literal: true

require "test_helper"

class ErrorsTest < Minitest::Test
  def setup
    setup_test_configuration
  end

  def teardown
    GolfGenius.reset_configuration!
  end

  def test_error_to_s_includes_status
    error = GolfGenius::NotFoundError.new(
      "Resource not found",
      http_status: 404,
      request_id: "req_123"
    )

    string = error.to_s

    assert_includes string, "404"
    assert_includes string, "req_123"
    assert_includes string, "Resource not found"
  end

  def test_error_attributes
    error = GolfGenius::APIError.new(
      "Test error",
      http_status: 400,
      http_body: { "error" => "Bad request" },
      http_headers: { "X-Request-Id" => "123" },
      request_id: "req_456"
    )

    assert_equal 400, error.http_status
    assert_equal({ "error" => "Bad request" }, error.http_body)
    assert_equal({ "X-Request-Id" => "123" }, error.http_headers)
    assert_equal "req_456", error.request_id
  end

  def test_error_inheritance
    assert_operator GolfGenius::AuthenticationError, :<, GolfGenius::GolfGeniusError
    assert_operator GolfGenius::NotFoundError, :<, GolfGenius::GolfGeniusError
    assert_operator GolfGenius::ValidationError, :<, GolfGenius::GolfGeniusError
    assert_operator GolfGenius::RateLimitError, :<, GolfGenius::GolfGeniusError
    assert_operator GolfGenius::ServerError, :<, GolfGenius::GolfGeniusError
    assert_operator GolfGenius::APIError, :<, GolfGenius::GolfGeniusError
    assert_operator GolfGenius::ConnectionError, :<, GolfGenius::GolfGeniusError
    assert_operator GolfGenius::ConfigurationError, :<, GolfGenius::GolfGeniusError
  end

  def test_not_found_error
    stub_api_request(method: :get, path: "/events", response_body: [], query: { "page" => "1" })

    error = assert_raises(GolfGenius::NotFoundError) do
      GolfGenius::Event.fetch("nonexistent")
    end

    assert_includes error.message, "Resource not found"
    assert_includes error.message, "nonexistent"
  end

  def test_authentication_error_401
    stub_error(
      method: :get,
      path: "/seasons",
      status: 401,
      error_body: ERROR_UNAUTHORIZED,
      query: { "page" => "1" }
    )

    error = assert_raises(GolfGenius::AuthenticationError) do
      GolfGenius::Season.list
    end

    assert_equal 401, error.http_status
    assert_includes error.message, "Unauthorized"
  end

  def test_authentication_error_403
    stub_error(
      method: :get,
      path: "/seasons",
      status: 403,
      error_body: ERROR_UNAUTHORIZED,
      query: { "page" => "1" }
    )

    error = assert_raises(GolfGenius::AuthenticationError) do
      GolfGenius::Season.list
    end

    assert_equal 403, error.http_status
  end

  def test_validation_error
    stub_error(
      method: :get,
      path: "/events",
      status: 422,
      error_body: ERROR_VALIDATION,
      query: { "page" => "1" }
    )

    error = assert_raises(GolfGenius::ValidationError) do
      GolfGenius::Event.list(page: 1)
    end

    assert_equal 422, error.http_status
    assert_includes error.message, "Validation failed"
  end

  def test_rate_limit_error
    stub_error(
      method: :get,
      path: "/events",
      status: 429,
      error_body: ERROR_RATE_LIMIT,
      query: { "page" => "1" }
    )

    error = assert_raises(GolfGenius::RateLimitError) do
      GolfGenius::Event.list(page: 1)
    end

    assert_equal 429, error.http_status
    assert_includes error.message, "Rate limit exceeded"
  end

  def test_server_error
    stub_error(
      method: :get,
      path: "/events",
      status: 500,
      error_body: ERROR_SERVER,
      query: { "page" => "1" }
    )

    error = assert_raises(GolfGenius::ServerError) do
      GolfGenius::Event.list(page: 1)
    end

    assert_equal 500, error.http_status
  end

  def test_connection_error_timeout
    stub_timeout(method: :get, path: "/events", query: { "page" => "1" })

    error = assert_raises(GolfGenius::ConnectionError) do
      GolfGenius::Event.list(page: 1)
    end

    assert_kind_of GolfGenius::ConnectionError, error
  end

  def test_connection_error_failure
    stub_connection_failure(method: :get, path: "/events", query: { "page" => "1" })

    error = assert_raises(GolfGenius::ConnectionError) do
      GolfGenius::Event.list(page: 1)
    end

    assert_includes error.message, "Connection"
  end

  def test_configuration_error_no_api_key
    GolfGenius.api_key = nil

    error = assert_raises(GolfGenius::ConfigurationError) do
      GolfGenius::Season.list
    end

    assert_includes error.message, "API key"
  end
end
