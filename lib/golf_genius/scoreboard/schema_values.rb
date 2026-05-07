# frozen_string_literal: true

module GolfGenius
  class Scoreboard
    module SchemaValues
      module State
        NOT_STARTED = "not_started"
        PLAYING = "playing"
        FINISHED = "finished"
        ELIMINATED = "eliminated"
        UNKNOWN = "unknown"

        VALUES = [
          NOT_STARTED,
          PLAYING,
          FINISHED,
          ELIMINATED,
          UNKNOWN,
        ].freeze
      end

      module Outcome
        DNS = "dns" # Did not start
        NS = "ns" # No show / did not start
        WD = "wd" # Withdrew
        DQ = "dq" # Disqualified
        CUT = "cut" # Missed the cut
        MC = "mc" # Missed cut
        NC = "nc" # No card / no contest
        UNKNOWN = "unknown" # Unrecognized Golf Genius disposition

        FROM_GOLF_GENIUS = {
          "DNS" => DNS,
          "NS" => NS,
          "WD" => WD,
          "DQ" => DQ,
          "CUT" => CUT,
          "MC" => MC,
          "NC" => NC,
        }.freeze

        VALUES = (FROM_GOLF_GENIUS.values + [UNKNOWN]).freeze
      end

      module LocationKind
        CITY_STATE = "city_state"
        COUNTRY = "country"
        FREEFORM = "freeform"
        UNKNOWN = "unknown"

        VALUES = [
          CITY_STATE,
          COUNTRY,
          FREEFORM,
          UNKNOWN,
        ].freeze
      end
    end
  end
end
