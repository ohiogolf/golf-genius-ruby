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
end
