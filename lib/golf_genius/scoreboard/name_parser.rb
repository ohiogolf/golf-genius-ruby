# frozen_string_literal: true

require_relative "name"

module GolfGenius
  class Scoreboard
    # Parses player names into Name objects.
    #
    # Handles various name formats found in Golf Genius data:
    # - Simple names: "John Doe"
    # - Names with suffixes: "Paul Schlimm Jr.", "Wyatt Worthington II"
    # - Names with comma before suffix: "John Doe, Sr.", "Paul Schlimm, Jr."
    # - Names in "Last, First" format: "Christy, Aaron", "Gerwin, Robert F. II"
    # - Names with (a) suffix: "Adam Black (a)"
    # - Hyphenated names: "Elijah Hall-Bromberg"
    # - Names with middle initials: "Robert F. Gerwin II (a)"
    # - Team names: "Abel Ferrer + Kyle Tracey"
    #
    # @example Parsing a simple name
    #   name = NameParser.parse("John Doe")
    #   name.first_name  # => "John"
    #   name.last_name   # => "Doe"
    #
    # @example Parsing a name with suffix
    #   name = NameParser.parse("Paul Schlimm Jr.")
    #   name.first_name  # => "Paul"
    #   name.last_name   # => "Schlimm"
    #   name.suffix      # => "Jr."
    #
    # @example Parsing a team name
    #   names = NameParser.parse("Abel Ferrer + Kyle Tracey")
    #   names[0].first_name  # => "Abel"
    #   names[1].first_name  # => "Kyle"
    #
    module NameParser
      # Team name separator used in Golf Genius data
      # Teams are represented as "Player1 + Player2"
      TEAM_SEPARATOR = " + "

      # Generational and professional suffixes to recognize
      # Matches with or without periods, case-insensitive
      # Includes: Jr., Sr., I-X (Roman numerals), Esq., MD, PhD, DDS, 1st-4th
      SUFFIX_PATTERN = /\A(Jr\.?|Sr\.?|I{1,3}|IV|VI{0,3}|IX|X|Esq\.?|[MD]D|PhD|DDS|\d+(st|nd|rd|th))\z/i

      # Parses a name (individual or team) into Name object(s).
      #
      # @param name [String, nil] the name to parse
      # @return [Name, Array<Name>, nil] parsed name(s) or nil if name is blank
      #
      def self.parse(name)
        return nil if name.nil? || name.to_s.strip.empty?

        # Handle team names (multiple players separated by TEAM_SEPARATOR)
        return parse_team(name) if name.include?(TEAM_SEPARATOR)

        parse_individual(name)
      end

      # Parses a team name into an array of Name objects.
      #
      # @param name [String] team name with players separated by TEAM_SEPARATOR
      # @return [Array<Name>] array of Name objects
      #
      def self.parse_team(name)
        name.split(TEAM_SEPARATOR).map { |player_name| parse_individual(player_name.strip) }
      end

      # Parses an individual name into a Name object.
      #
      # Extracts first name, last name, suffix, and metadata (like amateur indicator)
      # from the name string. Handles multiple formats:
      # - "First Last" or "First Middle Last"
      # - "First Last Jr." or "First Last, Jr."
      # - "Last, First" or "Last, First Jr."
      #
      # @param name [String] individual player name
      # @return [Name] Name object with parsed components
      #
      def self.parse_individual(name)
        name = name.strip
        metadata = []

        # Check for (a) suffix and store as metadata
        if name.end_with?("(a)")
          metadata << "(a)"
          name = name.sub(/\s*\(a\)\s*$/, "").strip
        end

        # Check for comma-separated formats
        if name.include?(",")
          # Split on comma to determine format
          parts = name.split(",").map(&:strip)
          after_comma = parts[1] || ""

          # If after comma is only a suffix, it's "First Last, Suffix" format
          # Otherwise it's "Last, First" format
          return parse_first_last_comma_suffix_format(name, metadata) if after_comma.match?(/\A#{SUFFIX_PATTERN}\z/)

          return parse_last_first_format(name, metadata)

        end

        # Split into parts
        parts = name.split(/\s+/)

        # Handle single name (edge case)
        if parts.length == 1
          return Name.new(
            first_name: "",
            last_name: parts[0],
            suffix: nil,
            metadata: metadata
          )
        end

        # Check if last part matches a suffix pattern
        suffix = nil
        if parts.last&.match?(SUFFIX_PATTERN)
          suffix = parts.pop
          # Normalize: add period to Jr/Sr if missing
          suffix = "#{suffix}." if suffix.match?(/\A(Jr|Sr)\z/i)
        end

        # Last remaining part is last_name
        # Everything else is first_name
        last_name = parts.pop
        first_name = parts.join(" ")

        Name.new(
          first_name: first_name,
          last_name: last_name,
          suffix: suffix,
          metadata: metadata
        )
      end

      # Parses a "First Last, Suffix" format name into a Name object.
      #
      # Handles formats like:
      # - "John Doe, Sr."
      # - "Paul Schlimm, Jr"
      # - "Wyatt Worthington, II"
      #
      # @param name [String] name in "First Last, Suffix" format
      # @param metadata [Array] any metadata already extracted
      # @return [Name] Name object with parsed components
      #
      def self.parse_first_last_comma_suffix_format(name, metadata)
        # Split on comma: "John Doe, Sr." -> ["John Doe", "Sr."]
        parts = name.split(",").map(&:strip)
        name_part = parts[0]
        suffix = parts[1] || ""

        # Normalize: add period to Jr/Sr if missing
        suffix = "#{suffix}." if suffix.match?(/\A(Jr|Sr)\z/i)

        # Parse the name part into first and last
        name_words = name_part.split(/\s+/)

        # Handle single name (edge case)
        if name_words.length == 1
          return Name.new(
            first_name: "",
            last_name: name_words[0],
            suffix: suffix,
            metadata: metadata
          )
        end

        last_name = name_words.pop
        first_name = name_words.join(" ")

        Name.new(
          first_name: first_name,
          last_name: last_name,
          suffix: suffix,
          metadata: metadata
        )
      end

      # Parses a "Last, First" format name into a Name object.
      #
      # Handles formats like:
      # - "Christy, Aaron"
      # - "Christy, Aaron Sr."
      # - "Worthington, Wyatt II"
      #
      # @param name [String] name in "Last, First" format
      # @param metadata [Array] any metadata already extracted
      # @return [Name] Name object with parsed components
      #
      def self.parse_last_first_format(name, metadata)
        # Split on comma: "Last, First Jr." -> ["Last", "First Jr."]
        parts = name.split(",").map(&:strip)
        last_name = parts[0]
        first_part = parts[1] || ""

        # Parse first_part for first_name and suffix
        first_words = first_part.split(/\s+/)
        suffix = nil
        if first_words.last&.match?(SUFFIX_PATTERN)
          suffix = first_words.pop
          # Normalize: add period to Jr/Sr if missing
          suffix = "#{suffix}." if suffix.match?(/\A(Jr|Sr)\z/i)
        end

        first_name = first_words.join(" ")

        Name.new(
          first_name: first_name,
          last_name: last_name,
          suffix: suffix,
          metadata: metadata
        )
      end
    end
  end
end
