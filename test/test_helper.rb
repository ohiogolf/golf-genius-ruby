# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "golf_genius"

require "minitest/autorun"
require "webmock/minitest"

WebMock.disable_net_connect!

TEST_API_KEY = "test_api_key_12345"
TEST_BASE_URL = "https://www.golfgenius.com"

module GolfGenius
  module TestHelpers
    def setup_test_configuration
      GolfGenius.reset_configuration!
      GolfGenius.api_key = TEST_API_KEY
    end
  end
end

class Minitest::Test
  include GolfGenius::TestHelpers
end
