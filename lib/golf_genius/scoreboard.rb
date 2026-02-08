# frozen_string_literal: true

require_relative "scoreboard/column"
require_relative "scoreboard/cell"
require_relative "scoreboard/round"
require_relative "scoreboard/rounds"
require_relative "scoreboard/scorecard"

module GolfGenius
  # Parses Golf Genius tournament results into structured, sortable leaderboards.
  #
  # Combines HTML (visual layout) and JSON (scoring data) responses from the API
  # into typed value objects for easy consumption.
  class Scoreboard # rubocop:disable Lint/EmptyClass
  end
end
