# frozen_string_literal: true

require "test_helper"

class SeasonTest < Minitest::Test
  def setup
    setup_test_configuration
  end

  def teardown
    GolfGenius.reset_configuration!
  end

  def test_list_seasons
    stub_api_request(method: :get, path: "/seasons", response_body: SEASONS, query: { "page" => "1" })
    stub_api_request(method: :get, path: "/seasons", response_body: [], query: { "page" => "2" })

    seasons = GolfGenius::Season.list

    assert_kind_of Array, seasons
    assert_equal 2, seasons.length
    assert_kind_of GolfGenius::Season, seasons.first
    assert_equal "season_001", seasons.first.id
    assert_equal "2026 Season", seasons.first.name
    assert_equal true, seasons.first.current
  end

  def test_list_seasons_with_custom_api_key
    custom_key = "custom_api_key"
    stub_request(:get, "#{TEST_BASE_URL}/api_v2/#{custom_key}/seasons?page=1").to_return(
      status: 200,
      body: SEASONS.to_json,
      headers: { "Content-Type" => "application/json" }
    )
    stub_request(:get, "#{TEST_BASE_URL}/api_v2/#{custom_key}/seasons?page=2").to_return(
      status: 200,
      body: [].to_json,
      headers: { "Content-Type" => "application/json" }
    )

    seasons = GolfGenius::Season.list(api_key: custom_key)

    assert_equal 2, seasons.length
  end

  def test_fetch_season
    stub_api_request(method: :get, path: "/seasons", response_body: SEASONS, query: { "page" => "1" })

    season = GolfGenius::Season.fetch("season_001")

    assert_kind_of GolfGenius::Season, season
    assert_equal "season_001", season.id
    assert_equal "2026 Season", season.name
    assert_equal true, season.current
  end

  def test_season_attributes
    season = GolfGenius::Season.construct_from(SEASON)

    assert_equal "season_001", season.id
    assert_equal "2026 Season", season.name
    assert_equal true, season.current
    assert_equal "2026-01-01", season.start_date
    assert_equal "2026-12-31", season.end_date
  end

  def test_season_to_h
    season = GolfGenius::Season.construct_from(SEASON)
    hash = season.to_h

    assert_kind_of Hash, hash
    assert_equal "season_001", hash[:id]
    assert_equal "2026 Season", hash[:name]
  end
end
