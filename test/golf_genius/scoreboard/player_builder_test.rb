# frozen_string_literal: true

require "test_helper"

class PlayerBuilderTest < Minitest::Test
  def test_players_strip_bare_jr_suffix_from_roster_last_name
    name = build_name(full_name: "John Smith Jr", first_name: "John", last_name: "Smith Jr")

    assert_equal "Smith", name[:last]
    assert_equal "Jr.", name[:suffix]
  end

  def test_players_strip_period_jr_suffix_from_roster_last_name
    name = build_name(full_name: "John Smith Jr.", first_name: "John", last_name: "Smith Jr.")

    assert_equal "Smith", name[:last]
    assert_equal "Jr.", name[:suffix]
  end

  def test_players_strip_bare_sr_suffix_from_roster_last_name
    name = build_name(full_name: "John Smith Sr", first_name: "John", last_name: "Smith Sr")

    assert_equal "Smith", name[:last]
    assert_equal "Sr.", name[:suffix]
  end

  def test_players_strip_roman_numeral_suffix_from_roster_last_name
    name = build_name(full_name: "Matthew Wilson IV", first_name: "Matthew", last_name: "Wilson IV")

    assert_equal "Wilson", name[:last]
    assert_equal "IV", name[:suffix]
  end

  def test_players_keep_roster_last_name_when_suffix_is_not_duplicated
    name = build_name(full_name: "Matthew Wilson IV", first_name: "Matthew", last_name: "Wilson")

    assert_equal "Wilson", name[:last]
    assert_equal "IV", name[:suffix]
  end

  def test_players_normalize_roster_name_parts
    name = build_name(full_name: "John Smith", first_name: "  John  ", last_name: "  Smith  ")

    assert_equal "John", name[:first]
    assert_equal "Smith", name[:last]
  end

  private

  def build_name(full_name:, first_name:, last_name:)
    builder = GolfGenius::Scoreboard::PlayerBuilder.new(
      aggregate: {
        name: full_name,
        member_cards: [],
      },
      member_ids: ["101"],
      roster_lookup: {
        by_member_id: {
          "101" => {
            member_id: "101",
            name: full_name,
            first_name: first_name,
            last_name: last_name,
          },
        },
        by_member_card_id: {},
      },
      tee_lookup: {
        by_player_roster_id: {},
        by_member_card_id: {},
        ordered_players: [],
      },
      location_builder: null_location_builder
    )

    builder.players.first[:name]
  end

  def null_location_builder
    @null_location_builder ||= Class.new do
      def self.build(**_options)
        nil
      end
    end
  end
end
