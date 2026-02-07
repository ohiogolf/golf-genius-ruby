# frozen_string_literal: true

require "test_helper"

class JsonParserTest < Minitest::Test
  def load_fixture(filename)
    File.read(File.join(__dir__, "../../fixtures/tournament_results", filename))
  end

  def test_initialize_requires_json
    error = assert_raises(ArgumentError) do
      GolfGenius::Scoreboard::JsonParser.new(nil)
    end

    assert_match(/json is required/, error.message)
  end

  def test_initialize_rejects_empty_json
    error = assert_raises(ArgumentError) do
      GolfGenius::Scoreboard::JsonParser.new("")
    end

    assert_match(/json is required/, error.message)
  end

  def test_parse_returns_hash_structure
    json = '{"name": "Test", "rounds": [], "scopes": []}'
    parser = GolfGenius::Scoreboard::JsonParser.new(json)
    result = parser.parse

    assert_kind_of Hash, result
    assert result.key?(:name)
    assert result.key?(:adjusted)
    assert result.key?(:rounds)
    assert result.key?(:aggregates)
  end

  def test_parse_extracts_tournament_metadata
    json = '{"name": "Test Tournament", "adjusted": true, "rounds": [], "scopes": []}'
    parser = GolfGenius::Scoreboard::JsonParser.new(json)
    result = parser.parse

    assert_equal "Test Tournament", result[:name]
    assert_equal true, result[:adjusted]
  end

  def test_parse_extracts_rounds
    json = load_fixture("multi_round_stroke_play.json")
    parser = GolfGenius::Scoreboard::JsonParser.new(json)
    result = parser.parse

    assert_equal 2, result[:rounds].length

    # Check R2
    assert_equal 2001, result[:rounds][0][:id]
    assert_equal "R2", result[:rounds][0][:name]
    assert_equal "2026-03-16", result[:rounds][0][:date]
    assert_equal true, result[:rounds][0][:in_progress]

    # Check R1
    assert_equal 2000, result[:rounds][1][:id]
    assert_equal "R1", result[:rounds][1][:name]
    assert_equal false, result[:rounds][1][:in_progress]
  end

  def test_parse_extracts_aggregates
    json = load_fixture("multi_round_stroke_play.json")
    parser = GolfGenius::Scoreboard::JsonParser.new(json)
    result = parser.parse

    # Should be keyed by aggregate ID
    assert_equal 3, result[:aggregates].length
    assert result[:aggregates].key?(1001)
    assert result[:aggregates].key?(1002)
    assert result[:aggregates].key?(1003)
  end

  def test_parse_aggregate_basic_data
    json = load_fixture("multi_round_stroke_play.json")
    parser = GolfGenius::Scoreboard::JsonParser.new(json)
    result = parser.parse

    agg = result[:aggregates][1001]

    assert_equal 1001, agg[:id]
    assert_equal ["101"], agg[:member_ids]
  end

  def test_parse_aggregate_rounds
    json = load_fixture("multi_round_stroke_play.json")
    parser = GolfGenius::Scoreboard::JsonParser.new(json)
    result = parser.parse

    agg = result[:aggregates][1001]

    # Should have data for both rounds
    assert_equal 2, agg[:rounds].length

    # Check R2 data
    r2 = agg[:rounds][2001]

    assert_equal "8", r2[:thru]
    assert_equal "-8", r2[:score]
    assert_equal "-", r2[:total]
    assert_equal "partial", r2[:status]

    # Check R1 data
    r1 = agg[:rounds][2000]

    assert_equal "F", r1[:thru]
    assert_equal "+16", r1[:score]
    assert_equal "88", r1[:total]
    assert_equal "completed", r1[:status]
  end

  def test_parse_current_round_scores
    json = load_fixture("multi_round_stroke_play.json")
    parser = GolfGenius::Scoreboard::JsonParser.new(json)
    result = parser.parse

    agg = result[:aggregates][1001]
    scores = agg[:current_round_scores]

    # Check hole-by-hole arrays
    assert_equal [4, 3, 3, 4, 2, 3, 3, 2, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil], scores[:gross_scores]
    assert_equal [4, 3, 3, 4, 2, 3, 3, 2, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil], scores[:net_scores]
    assert_equal [-1, -1, -1, -1, -1, -1, -1, -1, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil], scores[:to_par_gross]
    assert_equal [-1, -1, -1, -1, -1, -1, -1, -1, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil], scores[:to_par_net]

    # Check totals (R2 is partial, so no totals)
    assert_nil scores[:totals][:out]
    assert_nil scores[:totals][:in]
    assert_nil scores[:totals][:total]
  end

  def test_parse_previous_rounds_scores
    json = load_fixture("multi_round_stroke_play.json")
    parser = GolfGenius::Scoreboard::JsonParser.new(json)
    result = parser.parse

    agg = result[:aggregates][1001]
    prev = agg[:previous_rounds_scores]

    # Should have R1 data
    assert_equal 1, prev.length
    assert prev.key?(2000)

    r1 = prev[2000]

    assert_equal [4, 5, 3, 7, 6, 5, 6, 4, 7, 3, 5, 3, 7, 5, 3, 5, 3, 7], r1[:gross_scores]
    assert_equal 47, r1[:totals][:out]
    assert_equal 41, r1[:totals][:in]
    assert_equal 88, r1[:totals][:total]
  end

  def test_parse_team_with_multiple_member_ids
    json = load_fixture("multi_round_stroke_play.json")
    parser = GolfGenius::Scoreboard::JsonParser.new(json)
    result = parser.parse

    agg = result[:aggregates][1003]

    assert_equal %w[103 104], agg[:member_ids]
  end
end
