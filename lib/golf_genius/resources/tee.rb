# frozen_string_literal: true

module GolfGenius
  # Represents a tee configuration for a player or roster member.
  # Business: Tee name and metadata used for scoring/assignment.
  # Returned as a nested object on Player or RosterMember when provided.
  class Tee < GolfGeniusObject
    ATTRIBUTES = %i[
      id
      name
      abbreviation
      nine_hole_course
      created_at
      updated_at
      color
      course_id
      parent_id
    ].freeze

    define_attribute_methods!(ATTRIBUTES)
  end
end
