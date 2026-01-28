# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "golf_genius"

require "minitest/autorun"
require "webmock/minitest"

require_relative "fixtures/api_responses"

# Disable all external connections by default
WebMock.disable_net_connect!

# Test configuration
TEST_API_KEY = "test_api_key_12345"
TEST_BASE_URL = "https://www.golfgenius.com"

module GolfGenius
  module TestHelpers
    # Configures the gem for testing
    def setup_test_configuration
      GolfGenius.reset_configuration!
      GolfGenius.api_key = TEST_API_KEY
    end

    # Stubs a successful API response
    #
    # @param method [Symbol] HTTP method (:get, :post, etc.)
    # @param path [String] API path (without base URL or API key)
    # @param response_body [Hash, Array] The response body
    # @param status [Integer] HTTP status code (default: 200)
    # @param query [Hash, nil] Expected query parameters
    def stub_api_request(method:, path:, response_body:, status: 200, query: nil)
      url = "#{TEST_BASE_URL}/api_v2/#{TEST_API_KEY}#{path}"

      stub = stub_request(method, url)
      stub = stub.with(query: query) if query
      stub.to_return(
        status: status,
        body: response_body.to_json,
        headers: { "Content-Type" => "application/json" }
      )
    end

    # Stubs a list endpoint
    def stub_list(resource_path, response_body, query: nil)
      stub_api_request(
        method: :get,
        path: resource_path,
        response_body: response_body,
        query: query
      )
    end

    # Stubs a fetch endpoint
    def stub_fetch(resource_path, id, response_body)
      stub_api_request(
        method: :get,
        path: "#{resource_path}/#{id}",
        response_body: response_body
      )
    end

    # Stubs a nested resource endpoint
    def stub_nested(path, response_body, query: nil)
      stub_api_request(
        method: :get,
        path: path,
        response_body: response_body,
        query: query
      )
    end

    # Stubs an error response
    def stub_error(method:, path:, status:, error_body:)
      stub_api_request(
        method: method,
        path: path,
        response_body: error_body,
        status: status
      )
    end

    # Stubs a timeout error
    def stub_timeout(method:, path:)
      url = "#{TEST_BASE_URL}/api_v2/#{TEST_API_KEY}#{path}"
      stub_request(method, url).to_timeout
    end

    # Stubs a connection failure
    def stub_connection_failure(method:, path:)
      url = "#{TEST_BASE_URL}/api_v2/#{TEST_API_KEY}#{path}"
      stub_request(method, url).to_raise(Faraday::ConnectionFailed.new("Connection refused"))
    end
  end
end

# Include helpers in all test classes
class Minitest::Test
  include GolfGenius::TestHelpers
  include GolfGenius::TestFixtures
end
