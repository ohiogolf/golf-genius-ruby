# frozen_string_literal: true

module GolfGenius
  # Represents a course/tee setup for an event.
  # Business: The physical course and tees used for the event; defines pars, ratings, and yardages used for scoring.
  # Returned by {Event#courses} / {Event.courses}; not a top-level API resource.
  #
  # @example
  #   courses = event.courses
  #   courses.each { |c| puts "#{c.name} rating #{c.rating}" }
  class Course < GolfGeniusObject
  end
end
