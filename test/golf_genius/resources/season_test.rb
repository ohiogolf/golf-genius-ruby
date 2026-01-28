# frozen_string_literal: true

require "test_helper"

class SeasonTest < Minitest::Test
  def setup
    configure_test_api_key
  end

  def test_list_seasons
    skip "Set GOLF_GENIUS_API_KEY environment variable to run integration tests" unless ENV["GOLF_GENIUS_API_KEY"]

    VCR.use_cassette("seasons_list") do
      seasons = GolfGenius::Season.list
      assert_kind_of Array, seasons
    end
  end

  def test_retrieve_season
    VCR.use_cassette("season_retrieve") do
      # This will fail until you have a real season ID
      # season = GolfGenius::Season.retrieve("season_id")
      # assert_kind_of GolfGenius::Season, season
      # assert season.id
      skip "Need real season ID for integration test"
    end
  end

  def test_season_attributes
    season = GolfGenius::Season.construct_from(
      id: "123",
      name: "2026 Season",
      current: true
    )

    assert_equal "123", season.id
    assert_equal "2026 Season", season.name
    assert_equal true, season.current
  end
end
