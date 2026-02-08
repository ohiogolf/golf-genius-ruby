# frozen_string_literal: true

module GolfGenius
  class Scoreboard
    # US state data for normalizing state codes and names.
    #
    # Provides lookup by abbreviation or full name to get normalized data.
    module USStates
      # US states with abbreviations and full names
      STATES = {
        "AL" => "Alabama",
        "AK" => "Alaska",
        "AZ" => "Arizona",
        "AR" => "Arkansas",
        "CA" => "California",
        "CO" => "Colorado",
        "CT" => "Connecticut",
        "DE" => "Delaware",
        "FL" => "Florida",
        "GA" => "Georgia",
        "HI" => "Hawaii",
        "ID" => "Idaho",
        "IL" => "Illinois",
        "IN" => "Indiana",
        "IA" => "Iowa",
        "KS" => "Kansas",
        "KY" => "Kentucky",
        "LA" => "Louisiana",
        "ME" => "Maine",
        "MD" => "Maryland",
        "MA" => "Massachusetts",
        "MI" => "Michigan",
        "MN" => "Minnesota",
        "MS" => "Mississippi",
        "MO" => "Missouri",
        "MT" => "Montana",
        "NE" => "Nebraska",
        "NV" => "Nevada",
        "NH" => "New Hampshire",
        "NJ" => "New Jersey",
        "NM" => "New Mexico",
        "NY" => "New York",
        "NC" => "North Carolina",
        "ND" => "North Dakota",
        "OH" => "Ohio",
        "OK" => "Oklahoma",
        "OR" => "Oregon",
        "PA" => "Pennsylvania",
        "RI" => "Rhode Island",
        "SC" => "South Carolina",
        "SD" => "South Dakota",
        "TN" => "Tennessee",
        "TX" => "Texas",
        "UT" => "Utah",
        "VT" => "Vermont",
        "VA" => "Virginia",
        "WA" => "Washington",
        "WV" => "West Virginia",
        "WI" => "Wisconsin",
        "WY" => "Wyoming",
        "DC" => "District of Columbia",
      }.freeze

      # Reverse lookup: full name => abbreviation
      NAMES_TO_CODES = STATES.invert.freeze

      # Finds a US state by abbreviation or full name.
      #
      # Returns normalized data with both code and name.
      # Case-insensitive matching.
      #
      # @param input [String] state abbreviation (OH) or full name (Ohio)
      # @return [Hash, nil] hash with :code and :name keys, or nil if not found
      #
      # @example By abbreviation
      #   USStates.find("OH")  # => { code: "OH", name: "Ohio" }
      #
      # @example By full name
      #   USStates.find("Ohio")  # => { code: "OH", name: "Ohio" }
      #
      # @example Case insensitive
      #   USStates.find("oh")  # => { code: "OH", name: "Ohio" }
      #
      def self.find(input)
        return nil if input.nil? || input.strip.empty?

        input = input.strip

        # Try exact match by code (case-insensitive)
        code = input.upcase
        return { code: code, name: STATES[code] } if STATES.key?(code)

        # Try match by full name (case-insensitive)
        # Convert input to titlecase for comparison
        normalized_input = input.split.map(&:capitalize).join(" ")
        if NAMES_TO_CODES.key?(normalized_input)
          code = NAMES_TO_CODES[normalized_input]
          return { code: code, name: normalized_input }
        end

        # Not found
        nil
      end
    end
  end
end
