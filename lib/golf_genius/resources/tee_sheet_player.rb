# frozen_string_literal: true

module GolfGenius
  # Represents a player entry within a tee sheet pairing group.
  # Business: Player slot, name, position, and scoring data for a tee time group.
  # Returned as a nested object within TeeSheetGroup#players.
  class TeeSheetPlayer < GolfGeniusObject
    ATTRIBUTES = %i[
      name
      position
      player_roster_id
      score_array
    ].freeze

    define_attribute_methods!(ATTRIBUTES)
  end
end
