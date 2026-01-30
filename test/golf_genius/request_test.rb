# frozen_string_literal: true

require "test_helper"

class RequestTest < Minitest::Test
  def setup
    setup_test_configuration
  end

  def teardown
    GolfGenius.reset_configuration!
  end

  def test_execute_success_returns_body
    stub_api_request(
      method: :get,
      path: "/seasons",
      response_body: SEASONS,
      query: { "page" => "1" }
    )

    result = GolfGenius::APIOperations::Request.execute(
      method: :get,
      path: "/seasons",
      params: { "page" => "1" }
    )

    assert_kind_of Array, result
    assert_equal 2, result.length
    assert_equal "season_001", result.first["id"]
  end

  def test_execute_404_raises_not_found_error
    stub_error(
      method: :get,
      path: "/seasons/nonexistent",
      status: 404,
      error_body: ERROR_NOT_FOUND
    )

    error = assert_raises(GolfGenius::NotFoundError) do
      GolfGenius::APIOperations::Request.execute(
        method: :get,
        path: "/seasons/nonexistent"
      )
    end

    assert_equal 404, error.http_status
    assert_includes error.message, "Resource not found"
  end

  def test_execute_401_raises_authentication_error
    stub_error(
      method: :get,
      path: "/seasons",
      status: 401,
      error_body: ERROR_UNAUTHORIZED,
      query: { "page" => "1" }
    )

    error = assert_raises(GolfGenius::AuthenticationError) do
      GolfGenius::APIOperations::Request.execute(
        method: :get,
        path: "/seasons",
        params: { "page" => "1" }
      )
    end

    assert_equal 401, error.http_status
    assert_includes error.message, "Unauthorized"
  end

  def test_execute_without_api_key_raises_configuration_error
    GolfGenius.api_key = nil

    error = assert_raises(GolfGenius::ConfigurationError) do
      GolfGenius::APIOperations::Request.execute(
        method: :get,
        path: "/seasons"
      )
    end

    assert_includes error.message, "API key"
  end
end
