# frozen_string_literal: true

require "test_helper"

class GolfGeniusTest < Minitest::Test
  def test_version
    assert_equal "0.1.0", GolfGenius::VERSION
  end

  def test_api_docs_url_constant
    assert_equal "https://www.golfgenius.com/api/v2/docs", GolfGenius::API_DOCS_URL
  end
end
