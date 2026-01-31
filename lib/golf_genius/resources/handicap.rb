# frozen_string_literal: true

module GolfGenius
  # Represents handicap details for a player or roster member.
  # Business: Handicap indices and network identifiers used for scoring.
  # Returned as a nested object on Player or RosterMember.
  class Handicap < GolfGeniusObject
    ATTRIBUTES = {
      network_id: :handicap_network_id,
      index: :handicap_index,
      nine_hole_index: :nine_hole_handicap_index,
    }.freeze

    define_attribute_methods!(ATTRIBUTES)
  end
end
