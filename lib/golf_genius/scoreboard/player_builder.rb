# frozen_string_literal: true

require_relative "location_builder"
require_relative "name_parser"
require_relative "value_normalizer"

module GolfGenius
  class Scoreboard
    # Builds normalized player payloads and tee-sheet lookup context.
    class PlayerBuilder
      def self.build_roster_lookup(roster)
        roster.each_with_object({ by_member_id: {}, by_member_card_id: {} }) do |member, result|
          custom_fields = ValueNormalizer.normalize_hash(member[:custom_fields])
          country = LocationBuilder.normalize_country_object(member[:country])
          entry = {
            member_id: member.id.to_s,
            member_card_id: member[:member_card_id]&.to_s,
            name: ValueNormalizer.normalize_text(member.name),
            first_name: ValueNormalizer.normalize_text(member[:first_name]),
            last_name: ValueNormalizer.normalize_text(member[:last_name]),
            affiliation: ValueNormalizer.normalize_text(
              ValueNormalizer.field_value(custom_fields, "affiliation", "Affiliation")
            ),
            city: ValueNormalizer.normalize_text(ValueNormalizer.field_value(custom_fields, "city", "City")),
            state: ValueNormalizer.normalize_text(ValueNormalizer.field_value(custom_fields, "state", "State")),
            country: country,
          }

          result[:by_member_id][entry[:member_id]] = entry
          result[:by_member_card_id][entry[:member_card_id]] = entry if entry[:member_card_id]
        end
      end

      def self.build_tee_lookup(tee_sheet)
        initial_lookup = {
          by_player_roster_id: {},
          by_member_card_id: {},
          ordered_players: [],
        }

        tee_sheet.each_with_object(initial_lookup) do |group, result|
          group.players.each do |player|
            entry = {
              name: ValueNormalizer.normalize_text(player.respond_to?(:name) ? player.name : player[:name]),
              tee_time: ValueNormalizer.normalize_text(group.tee_time),
              starting_hole: group[:starting_hole],
              player_roster_id: player[:player_roster_id]&.to_s,
              member_card_id: player[:member_card_id]&.to_s,
              ggid: player[:player_ggid],
              tee: player[:tee]&.to_h,
              score_array: Array(player.score_array),
            }

            result[:by_player_roster_id][entry[:player_roster_id]] = entry if entry[:player_roster_id]
            result[:by_member_card_id][entry[:member_card_id]] = entry if entry[:member_card_id]
            result[:ordered_players] << entry
          end
        end
      end

      def initialize(aggregate:, member_ids:, roster_lookup:, tee_lookup:, location_builder: LocationBuilder)
        @aggregate = aggregate
        @member_ids = member_ids
        @roster_lookup = roster_lookup
        @tee_lookup = tee_lookup
        @location_builder = location_builder
      end

      def player_contexts
        @player_contexts ||= @member_ids.map do |member_id|
          roster_member = @roster_lookup[:by_member_id][member_id]
          member_card_id = member_card_id_for(member_id, roster_member)

          {
            member_id: member_id,
            member_card_id: member_card_id,
            roster_member: roster_member,
            tee_player: tee_player_for(member_id, member_card_id),
          }
        end
      end

      def players
        player_contexts.map do |player_context|
          member_id = player_context[:member_id]
          roster_member = player_context[:roster_member]
          tee_player = player_context[:tee_player]

          {
            member_id: member_id,
            member_card_id: player_context[:member_card_id],
            player_roster_id: tee_player&.dig(:player_roster_id) || member_id,
            ggid: ValueNormalizer.normalize_blank(tee_player&.dig(:ggid)),
            name: build_player_name(roster_member),
            location: @location_builder.build(aggregate: @aggregate, roster_member: roster_member),
            tee: simplify_tee(tee_player&.dig(:tee)),
          }
        end
      end

      private

      def member_card_id_for(member_id, roster_member)
        card = Array(@aggregate[:member_cards]).find { |entry| entry[:member_id] == member_id }
        return card[:member_card_id] if card

        roster_member&.dig(:member_card_id)
      end

      def tee_player_for(member_id, member_card_id)
        @tee_lookup[:by_player_roster_id][member_id] || @tee_lookup[:by_member_card_id][member_card_id]
      end

      def build_player_name(roster_member)
        full_name = player_display_name(roster_member)
        parsed_name = parse_player_name(full_name)

        {
          full: full_name,
          first: roster_name_part(roster_member, :first_name) || parsed_name&.first_name,
          last: last_name_without_duplicated_suffix(roster_member, parsed_name),
          suffix: parsed_name&.suffix,
          metadata: parsed_name&.metadata || [],
          amateur: parsed_name&.amateur? || false,
        }
      end

      def player_display_name(roster_member)
        if @member_ids.length == 1 && @aggregate[:name]
          ValueNormalizer.normalize_text(@aggregate[:name])
        else
          ValueNormalizer.normalize_text(roster_member&.dig(:name) || @aggregate[:name])
        end
      end

      def parse_player_name(full_name)
        return nil unless full_name
        return nil if @member_ids.length != 1

        parsed = NameParser.parse(full_name)
        parsed.is_a?(Array) ? nil : parsed
      end

      def roster_name_part(roster_member, key)
        ValueNormalizer.normalize_text(roster_member&.dig(key))
      end

      def last_name_without_duplicated_suffix(roster_member, parsed_name)
        roster_last_name = roster_name_part(roster_member, :last_name)
        return parsed_name&.last_name if suffix_embedded_in_last_name?(roster_last_name, parsed_name)

        roster_last_name || parsed_name&.last_name
      end

      def suffix_embedded_in_last_name?(roster_last_name, parsed_name)
        return false if roster_last_name.nil? || parsed_name.nil?
        return false if parsed_name.last_name.nil? || parsed_name.suffix.nil?

        suffix = Regexp.escape(parsed_name.suffix.sub(/\.\z/, ""))
        roster_last_name.match?(/\A#{Regexp.escape(parsed_name.last_name)}\s+#{suffix}\.?\z/i)
      end

      def simplify_tee(tee)
        return nil unless tee

        {
          name: ValueNormalizer.normalize_text(tee[:name] || tee["name"]),
          abbreviation: ValueNormalizer.normalize_text(tee[:abbreviation] || tee["abbreviation"]),
          color: ValueNormalizer.normalize_blank(tee[:color] || tee["color"]),
        }
      end
    end
  end
end
