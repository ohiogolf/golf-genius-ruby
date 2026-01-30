# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "golf_genius"

require "minitest/autorun"
require "webmock/minitest"

require_relative "fixtures/api_responses"

WebMock.disable_net_connect!

TEST_API_KEY = "test_api_key_12345"
TEST_BASE_URL = "https://www.golfgenius.com"

module GolfGenius
  module TestHelpers
    def setup_test_configuration
      GolfGenius.reset_configuration!
      GolfGenius.api_key = TEST_API_KEY
    end

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

    def stub_list(resource_path, response_body, query: nil)
      stub_api_request(
        method: :get,
        path: resource_path,
        response_body: response_body,
        query: query
      )
    end

    def stub_fetch(resource_path, id, response_body)
      stub_api_request(
        method: :get,
        path: "#{resource_path}/#{id}",
        response_body: response_body
      )
    end

    def stub_error(method:, path:, status:, error_body:, query: nil)
      stub_api_request(
        method: method,
        path: path,
        response_body: error_body,
        status: status,
        query: query
      )
    end

    def stub_timeout(method:, path:, query: nil)
      url = "#{TEST_BASE_URL}/api_v2/#{TEST_API_KEY}#{path}"
      stub = stub_request(method, url)
      stub = stub.with(query: query) if query
      stub.to_timeout
    end

    def stub_connection_failure(method:, path:, query: nil)
      url = "#{TEST_BASE_URL}/api_v2/#{TEST_API_KEY}#{path}"
      stub = stub_request(method, url)
      stub = stub.with(query: query) if query
      stub.to_raise(Faraday::ConnectionFailed.new("Connection refused"))
    end
  end
end

class Minitest::Test
  include GolfGenius::TestHelpers
  include GolfGenius::TestFixtures
end
