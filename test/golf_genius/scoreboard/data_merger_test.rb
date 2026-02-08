# frozen_string_literal: true

require "test_helper"

class DataMergerTest < Minitest::Test
  def load_fixture(filename)
    File.read(File.join(__dir__, "../../fixtures/tournament_results", filename))
  end

  def setup
    html = load_fixture("multi_round_stroke_play.html")
    json = load_fixture("multi_round_stroke_play.json")

    @html_parser = GolfGenius::Scoreboard::HtmlParser.new(html)
    @json_parser = GolfGenius::Scoreboard::JsonParser.new(json)

    @html_data = @html_parser.parse
    @json_data = @json_parser.parse
    @fetched_round_id = 2001 # R2
  end

  def test_merge_returns_hash_structure
    merger = GolfGenius::Scoreboard::DataMerger.new(@html_data, @json_data, @fetched_round_id)
    result = merger.merge

    assert_kind_of Hash, result
    assert result.key?(:tournament_meta)
    assert result.key?(:rows)
  end

  def test_merge_builds_tournament_meta
    merger = GolfGenius::Scoreboard::DataMerger.new(@html_data, @json_data, @fetched_round_id)
    result = merger.merge

    meta = result[:tournament_meta]

    assert_equal "Test Tournament", meta[:name]
    assert_equal false, meta[:adjusted]
    assert_equal 2, meta[:rounds].length
    assert_nil meta[:cut_text]
  end

  def test_merge_preserves_row_metadata
    merger = GolfGenius::Scoreboard::DataMerger.new(@html_data, @json_data, @fetched_round_id)
    result = merger.merge

    assert_equal 3, result[:rows].length

    row = result[:rows][0]

    assert_equal 1001, row[:id]
    assert_equal "Player A", row[:name]
    assert_equal ["101"], row[:player_ids]
    assert_equal "City A", row[:affiliation]
    assert_equal false, row[:cut]
    assert_kind_of Array, row[:cells]
  end

  def test_merge_injects_round_data
    merger = GolfGenius::Scoreboard::DataMerger.new(@html_data, @json_data, @fetched_round_id)
    result = merger.merge

    row = result[:rows][0]

    assert row.key?(:rounds)
    assert_kind_of Hash, row[:rounds]

    # Should have data for both rounds
    assert row[:rounds].key?(2001) # R2
    assert row[:rounds].key?(2000) # R1
  end

  def test_merge_injects_scorecard_for_current_round
    merger = GolfGenius::Scoreboard::DataMerger.new(@html_data, @json_data, @fetched_round_id)
    result = merger.merge

    row = result[:rows][0]
    r2 = row[:rounds][2001]

    assert r2.key?(:scorecard)
    scorecard = r2[:scorecard]

    # Check round metadata
    assert_equal "8", scorecard[:thru]
    assert_equal "-8", scorecard[:score]
    assert_equal "partial", scorecard[:status]

    # Check hole-by-hole scores
    assert_equal [4, 3, 3, 4, 2, 3, 3, 2, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
                 scorecard[:gross_scores]
    assert_equal [-1, -1, -1, -1, -1, -1, -1, -1, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
                 scorecard[:to_par_gross]

    # Check totals (partial round, so no totals)
    assert_nil scorecard[:totals][:out]
    assert_nil scorecard[:totals][:in]
    assert_nil scorecard[:totals][:total]
  end

  def test_merge_injects_scorecard_for_previous_round
    merger = GolfGenius::Scoreboard::DataMerger.new(@html_data, @json_data, @fetched_round_id)
    result = merger.merge

    row = result[:rows][0]
    r1 = row[:rounds][2000]

    assert r1.key?(:scorecard)
    scorecard = r1[:scorecard]

    # Check round metadata
    assert_equal "F", scorecard[:thru]
    assert_equal "+16", scorecard[:score]
    assert_equal "completed", scorecard[:status]

    # Check hole-by-hole scores from previous_rounds_scores
    assert_equal [4, 5, 3, 7, 6, 5, 6, 4, 7, 3, 5, 3, 7, 5, 3, 5, 3, 7], scorecard[:gross_scores]

    # Check totals
    assert_equal 47, scorecard[:totals][:out]
    assert_equal 41, scorecard[:totals][:in]
    assert_equal 88, scorecard[:totals][:total]
  end

  def test_merge_raises_error_on_missing_json_aggregate
    # Remove an aggregate from JSON
    @json_data[:aggregates].delete(1001)

    merger = GolfGenius::Scoreboard::DataMerger.new(@html_data, @json_data, @fetched_round_id)

    error = assert_raises(GolfGenius::ValidationError) do
      merger.merge
    end

    assert_match(/HTML row 1001 .* has no matching JSON row data/, error.message)
  end

  def test_merge_raises_error_on_player_id_mismatch
    # Change player_ids in JSON
    @json_data[:aggregates][1001][:member_ids] = ["999"]

    merger = GolfGenius::Scoreboard::DataMerger.new(@html_data, @json_data, @fetched_round_id)

    error = assert_raises(GolfGenius::ValidationError) do
      merger.merge
    end

    assert_match(/Player ID mismatch for row 1001/, error.message)
  end

  def test_merge_handles_team_with_multiple_players
    merger = GolfGenius::Scoreboard::DataMerger.new(@html_data, @json_data, @fetched_round_id)
    result = merger.merge

    # Team C has two players
    team_row = result[:rows][2]

    assert_equal 1003, team_row[:id]
    assert_equal %w[103 104], team_row[:player_ids]
  end
end
