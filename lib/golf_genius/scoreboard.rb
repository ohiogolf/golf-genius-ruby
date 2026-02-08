# frozen_string_literal: true

require_relative "scoreboard/column"
require_relative "scoreboard/cell"
require_relative "scoreboard/round"
require_relative "scoreboard/rounds"
require_relative "scoreboard/scorecard"
require_relative "scoreboard/us_states"
require_relative "scoreboard/affiliation"
require_relative "scoreboard/affiliation_parser"
require_relative "scoreboard/name"
require_relative "scoreboard/name_parser"
require_relative "scoreboard/html_parser"
require_relative "scoreboard/json_parser"
require_relative "scoreboard/data_merger"
require_relative "scoreboard/column_decomposer"
require_relative "scoreboard/row_decomposer"

module GolfGenius
  # Parses Golf Genius tournament results into structured, sortable leaderboards.
  #
  # Combines HTML (visual layout) and JSON (scoring data) responses from the API
  # into typed value objects for easy consumption.
  class Scoreboard # rubocop:disable Lint/EmptyClass
  end
end
