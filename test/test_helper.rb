# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "golf_genius"

require "minitest/autorun"
require "webmock/minitest"
require "vcr"

# Configure VCR for recording API interactions
VCR.configure do |config|
  config.cassette_library_dir = "test/fixtures"
  config.hook_into :webmock
  config.filter_sensitive_data("<API_KEY>") { ENV["GOLF_GENIUS_API_KEY"] }
  config.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: [:method, :uri, :body]
  }
end

# Helper to configure API key for tests
def configure_test_api_key
  GolfGenius.api_key = ENV["GOLF_GENIUS_API_KEY"] || "test_api_key"
end
