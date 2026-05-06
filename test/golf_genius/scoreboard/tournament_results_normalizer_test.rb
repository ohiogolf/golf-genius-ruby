# frozen_string_literal: true

require "test_helper"

class TournamentResultsNormalizerTest < Minitest::Test
  def test_normalize_uses_fallback_rounds_when_payload_rounds_are_empty
    json_data = {
      name: "Test Tournament",
      adjusted: false,
      rounds: [],
      aggregates: {},
    }
    fallback_rounds = [
      { id: 2001, name: "Round 1", date: "2026-03-15", in_progress: false },
    ]

    result = normalizer(json_data, fallback_rounds: fallback_rounds).normalize

    assert_equal [{ id: 2001, name: "R1", date: "2026-03-15", in_progress: false }], result[:rounds]
  end

  def test_normalize_prefers_fallback_round_status_over_payload_round_status
    json_data = {
      name: "Test Tournament",
      adjusted: false,
      rounds: [
        { id: 2001, name: "Round 2", date: "2026-03-15", in_progress: true, status: "in progress" },
        { id: 2000, name: "Round 1", date: "2026-03-15", in_progress: true, status: "in progress" },
      ],
      aggregates: {},
    }
    fallback_rounds = [
      { id: 2000, name: "Round 1", date: "2026-03-15", in_progress: false, status: "completed" },
      { id: 2001, name: "Round 2", date: "2026-03-15", in_progress: true, status: "in progress" },
    ]

    result = normalizer(json_data, fallback_rounds: fallback_rounds).normalize

    assert_equal "completed", result[:rounds][0][:status]
    assert_equal false, result[:rounds][0][:in_progress]
    assert_equal "in progress", result[:rounds][1][:status]
  end

  def test_normalize_canonicalizes_round_names_when_fallback_name_differs
    json_data = {
      name: "Test Tournament",
      adjusted: false,
      rounds: [
        { id: 2000, name: "R1", date: "2026-03-15", in_progress: false, status: "completed" },
        { id: 2001, name: "Round 2", date: "2026-03-15", in_progress: true, status: "in progress" },
      ],
      aggregates: {},
    }
    fallback_rounds = [
      { id: 2000, name: "Round 1", date: "2026-03-15", in_progress: false, status: "completed" },
      { id: 2001, name: "Round 2", date: "2026-03-15", in_progress: true, status: "in progress" },
    ]

    result = normalizer(json_data, fallback_rounds: fallback_rounds).normalize

    assert_equal "R1", result[:rounds][0][:name]
    assert_equal "R2", result[:rounds][1][:name]
    assert_equal "completed", result[:rounds][0][:status]
    assert_equal "in progress", result[:rounds][1][:status]
  end

  def test_normalize_canonicalizes_payload_verbose_round_names_without_fallback
    json_data = {
      name: "Test Tournament",
      adjusted: false,
      rounds: [
        { id: 2000, name: "Round 1", date: "2026-03-15", in_progress: false, status: "completed", index: 1 },
        { id: 2001, name: "Round 2", date: "2026-03-16", in_progress: true, status: "in progress", index: 2 },
      ],
      aggregates: {},
    }

    result = normalizer(json_data).normalize

    assert_equal "R1", result[:rounds][0][:name]
    assert_equal "R2", result[:rounds][1][:name]
  end

  def test_normalize_synthesizes_fetched_round_when_row_rounds_are_missing
    json_data = {
      name: "Test Tournament",
      adjusted: false,
      rounds: [{ id: 2001, name: "Round 1", date: "2026-03-15", in_progress: false }],
      aggregates: {
        1001 => {
          id: 1001,
          member_ids: ["101"],
          rounds: {},
          current_round_summary: {
            score: "-2",
            total: "69",
          },
          current_round_scores: {
            gross_scores: [4, 4, 3, 4, 5, 5, 3, 4, 3, 4, 4, 3, 4, 4, 3, 4, 4, 4],
            net_scores: [4, 4, 3, 4, 5, 5, 3, 4, 3, 4, 4, 3, 4, 4, 3, 4, 4, 4],
            to_par_gross: [0, 0, 0, -1, 1, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, -1, 0],
            to_par_net: [0, 0, 0, -1, 1, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, -1, 0],
            totals: { out: 35, in: 34, total: 69 },
          },
          previous_rounds_scores: {},
        },
      },
    }

    result = normalizer(json_data).normalize
    round = result[:aggregates][1001][:rounds][2001]

    assert_equal "F", round[:thru]
    assert_equal "-2", round[:score]
    assert_equal "69", round[:total]
    assert_equal "completed", round[:status]
  end

  def test_normalize_does_not_synthesize_partial_round_as_completed
    json_data = {
      name: "Test Tournament",
      adjusted: false,
      rounds: [{ id: 2001, name: "Round 1", date: "2026-03-15", in_progress: true }],
      aggregates: {
        1001 => {
          id: 1001,
          member_ids: ["101"],
          rounds: {},
          current_round_summary: {
            score: "E",
            total: "36",
          },
          current_round_scores: {
            gross_scores: [4, 4, 4, 4, 4, 4, 4, 4, 4, nil, nil, nil, nil, nil, nil, nil, nil, nil],
            net_scores: [],
            to_par_gross: [],
            to_par_net: [],
            totals: { out: 36, in: nil, total: nil },
          },
          previous_rounds_scores: {},
        },
      },
    }

    result = normalizer(json_data).normalize
    round = result[:aggregates][1001][:rounds][2001]

    assert_equal "9", round[:thru]
    assert_equal "partial", round[:status]
  end

  def test_normalize_derives_completed_status_from_complete_totals
    json_data = {
      name: "Test Tournament",
      adjusted: false,
      rounds: [{ id: 2001, name: "Round 1", date: "2026-03-15", in_progress: false }],
      aggregates: {
        1001 => {
          id: 1001,
          member_ids: ["101"],
          rounds: {},
          current_round_summary: {
            score: "-2",
            total: "69",
          },
          current_round_scores: {
            gross_scores: [4, 4, 3, 4, 5, 5, 3, 4, 3, 4, 4, 3, 4, 4, 3, 4, 4, 4],
            net_scores: [],
            to_par_gross: [],
            to_par_net: [],
            totals: { out: 35, in: 34, total: 69 },
          },
          previous_rounds_scores: {},
        },
      },
    }

    result = normalizer(json_data).normalize
    round = result[:aggregates][1001][:rounds][2001]

    assert_equal "F", round[:thru]
    assert_equal "completed", round[:status]
  end

  private

  def normalizer(json_data, fetched_round_id: 2001, fallback_rounds: [])
    GolfGenius::Scoreboard::TournamentResultsNormalizer.new(
      json_data,
      fetched_round_id: fetched_round_id,
      fallback_rounds: fallback_rounds
    )
  end
end
