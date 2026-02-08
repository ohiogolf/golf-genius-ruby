# frozen_string_literal: true

require "test_helper"

class NameParserTest < Minitest::Test
  # Test simple names
  def test_parse_simple_name
    result = GolfGenius::Scoreboard::NameParser.parse("John Doe")

    assert_instance_of GolfGenius::Scoreboard::Name, result
    assert_equal "John", result.first_name
    assert_equal "Doe", result.last_name
    assert_nil result.suffix
    assert_empty result.metadata
  end

  def test_parse_name_with_middle_name
    result = GolfGenius::Scoreboard::NameParser.parse("John Michael Doe")

    assert_equal "John Michael", result.first_name
    assert_equal "Doe", result.last_name
  end

  def test_parse_name_with_middle_initial
    result = GolfGenius::Scoreboard::NameParser.parse("Robert F. Gerwin")

    assert_equal "Robert F.", result.first_name
    assert_equal "Gerwin", result.last_name
  end

  # Test names with generational suffixes
  def test_parse_name_with_jr_suffix
    result = GolfGenius::Scoreboard::NameParser.parse("Paul Schlimm Jr.")

    assert_equal "Paul", result.first_name
    assert_equal "Schlimm", result.last_name
    assert_equal "Jr.", result.suffix
  end

  def test_parse_name_with_sr_suffix
    result = GolfGenius::Scoreboard::NameParser.parse("John Smith Sr.")

    assert_equal "John", result.first_name
    assert_equal "Smith", result.last_name
    assert_equal "Sr.", result.suffix
  end

  def test_parse_name_with_roman_numeral_ii
    result = GolfGenius::Scoreboard::NameParser.parse("Wyatt Worthington II")

    assert_equal "Wyatt", result.first_name
    assert_equal "Worthington", result.last_name
    assert_equal "II", result.suffix
  end

  def test_parse_name_with_roman_numeral_iii
    result = GolfGenius::Scoreboard::NameParser.parse("Jeg Coughlin III")

    assert_equal "Jeg", result.first_name
    assert_equal "Coughlin", result.last_name
    assert_equal "III", result.suffix
  end

  def test_parse_name_with_roman_numeral_iv
    result = GolfGenius::Scoreboard::NameParser.parse("Bobby Kincaid IV")

    assert_equal "Bobby", result.first_name
    assert_equal "Kincaid", result.last_name
    assert_equal "IV", result.suffix
  end

  def test_parse_name_with_roman_numeral_v
    result = GolfGenius::Scoreboard::NameParser.parse("John Smith V")

    assert_equal "John", result.first_name
    assert_equal "Smith", result.last_name
    assert_equal "V", result.suffix
  end

  def test_parse_name_with_roman_numeral_vi
    result = GolfGenius::Scoreboard::NameParser.parse("John Smith VI")

    assert_equal "John", result.first_name
    assert_equal "Smith", result.last_name
    assert_equal "VI", result.suffix
  end

  def test_parse_name_with_jr_no_period
    result = GolfGenius::Scoreboard::NameParser.parse("Paul Schlimm Jr")

    assert_equal "Paul", result.first_name
    assert_equal "Schlimm", result.last_name
    assert_equal "Jr.", result.suffix  # Normalized to include period
  end

  def test_parse_name_with_sr_no_period
    result = GolfGenius::Scoreboard::NameParser.parse("John Smith Sr")

    assert_equal "John", result.first_name
    assert_equal "Smith", result.last_name
    assert_equal "Sr.", result.suffix  # Normalized to include period
  end

  # Test names with (a) amateur suffix - stored as metadata
  def test_parse_name_with_amateur_suffix
    result = GolfGenius::Scoreboard::NameParser.parse("Adam Black (a)")

    assert_equal "Adam", result.first_name
    assert_equal "Black", result.last_name
    assert_nil result.suffix
    assert_equal ["(a)"], result.metadata
    assert_predicate result, :amateur?
  end

  def test_parse_name_with_suffix_and_amateur
    result = GolfGenius::Scoreboard::NameParser.parse("Robert F. Gerwin II (a)")

    assert_equal "Robert F.", result.first_name
    assert_equal "Gerwin", result.last_name
    assert_equal "II", result.suffix
    assert_equal ["(a)"], result.metadata
    assert_predicate result, :amateur?
  end

  # Test hyphenated names
  def test_parse_hyphenated_last_name
    result = GolfGenius::Scoreboard::NameParser.parse("Elijah Hall-Bromberg")

    assert_equal "Elijah", result.first_name
    assert_equal "Hall-Bromberg", result.last_name
  end

  def test_parse_hyphenated_first_name
    result = GolfGenius::Scoreboard::NameParser.parse("Mary-Jane Wilson")

    assert_equal "Mary-Jane", result.first_name
    assert_equal "Wilson", result.last_name
  end

  def test_parse_hyphenated_name_with_amateur_suffix
    result = GolfGenius::Scoreboard::NameParser.parse("Huai-Chien Hsu (a)")

    assert_equal "Huai-Chien", result.first_name
    assert_equal "Hsu", result.last_name
  end

  # Test edge cases
  def test_parse_single_name
    result = GolfGenius::Scoreboard::NameParser.parse("Madonna")

    assert_equal "", result.first_name
    assert_equal "Madonna", result.last_name
  end

  def test_parse_nil_name
    result = GolfGenius::Scoreboard::NameParser.parse(nil)

    assert_nil result
  end

  def test_parse_empty_string
    result = GolfGenius::Scoreboard::NameParser.parse("")

    assert_nil result
  end

  def test_parse_whitespace_only
    result = GolfGenius::Scoreboard::NameParser.parse("   ")

    assert_nil result
  end

  # Test team names
  def test_parse_team_with_two_players
    result = GolfGenius::Scoreboard::NameParser.parse("Abel Ferrer + Kyle Tracey")

    assert_instance_of Array, result
    assert_equal 2, result.length

    assert_equal "Abel", result[0].first_name
    assert_equal "Ferrer", result[0].last_name

    assert_equal "Kyle", result[1].first_name
    assert_equal "Tracey", result[1].last_name
  end

  def test_parse_team_with_suffixes
    result = GolfGenius::Scoreboard::NameParser.parse("John Smith Jr. + Bob Jones Sr.")

    assert_instance_of Array, result
    assert_equal 2, result.length

    assert_equal "John", result[0].first_name
    assert_equal "Smith", result[0].last_name
    assert_equal "Jr.", result[0].suffix

    assert_equal "Bob", result[1].first_name
    assert_equal "Jones", result[1].last_name
    assert_equal "Sr.", result[1].suffix
  end

  def test_parse_team_with_amateur_suffixes
    result = GolfGenius::Scoreboard::NameParser.parse("Adam Black (a) + John Doe (a)")

    assert_instance_of Array, result
    assert_equal 2, result.length

    assert_equal "Adam", result[0].first_name
    assert_equal "Black", result[0].last_name

    assert_equal "John", result[1].first_name
    assert_equal "Doe", result[1].last_name
  end

  def test_parse_team_with_complex_names
    result = GolfGenius::Scoreboard::NameParser.parse("Robert F. Gerwin II (a) + Elijah Hall-Bromberg")

    assert_instance_of Array, result
    assert_equal 2, result.length

    assert_equal "Robert F.", result[0].first_name
    assert_equal "Gerwin", result[0].last_name
    assert_equal "II", result[0].suffix
    assert_equal ["(a)"], result[0].metadata

    assert_equal "Elijah", result[1].first_name
    assert_equal "Hall-Bromberg", result[1].last_name
    assert_nil result[1].suffix
    assert_empty result[1].metadata
  end

  # Test names with initials
  def test_parse_name_with_initials_only
    result = GolfGenius::Scoreboard::NameParser.parse("T.J. Kreusch")

    assert_equal "T.J.", result.first_name
    assert_equal "Kreusch", result.last_name
  end

  def test_parse_name_with_first_initial
    result = GolfGenius::Scoreboard::NameParser.parse("C.A. Carter (a)")

    assert_equal "C.A.", result.first_name
    assert_equal "Carter", result.last_name
  end

  # Test whitespace handling
  def test_parse_name_with_leading_trailing_whitespace
    result = GolfGenius::Scoreboard::NameParser.parse("  John Doe  ")

    assert_equal "John", result.first_name
    assert_equal "Doe", result.last_name
  end

  def test_parse_name_with_extra_spaces_between_names
    result = GolfGenius::Scoreboard::NameParser.parse("John   Doe")

    assert_equal "John", result.first_name
    assert_equal "Doe", result.last_name
  end

  def test_parse_name_with_multiple_spaces_and_middle_name
    result = GolfGenius::Scoreboard::NameParser.parse("Robert  F.  Gerwin")

    assert_equal "Robert F.", result.first_name
    assert_equal "Gerwin", result.last_name
  end

  def test_parse_team_with_extra_spaces_around_separator
    result = GolfGenius::Scoreboard::NameParser.parse("John Doe  +  Jane Smith")

    assert_instance_of Array, result
    assert_equal 2, result.length

    assert_equal "John", result[0].first_name
    assert_equal "Doe", result[0].last_name

    assert_equal "Jane", result[1].first_name
    assert_equal "Smith", result[1].last_name
  end

  def test_parse_comma_format_with_extra_spaces
    result = GolfGenius::Scoreboard::NameParser.parse("Christy,  Aaron")

    assert_equal "Aaron", result.first_name
    assert_equal "Christy", result.last_name
  end

  # Test comma-separated "First Last, Suffix" format
  def test_parse_first_last_comma_suffix_format
    result = GolfGenius::Scoreboard::NameParser.parse("John Doe, Sr.")

    assert_equal "John", result.first_name
    assert_equal "Doe", result.last_name
    assert_equal "Sr.", result.suffix
  end

  def test_parse_first_last_comma_suffix_no_period
    result = GolfGenius::Scoreboard::NameParser.parse("John Doe, Sr")

    assert_equal "John", result.first_name
    assert_equal "Doe", result.last_name
    assert_equal "Sr.", result.suffix # Normalized to include period
  end

  def test_parse_first_last_comma_suffix_with_jr
    result = GolfGenius::Scoreboard::NameParser.parse("Paul Schlimm, Jr.")

    assert_equal "Paul", result.first_name
    assert_equal "Schlimm", result.last_name
    assert_equal "Jr.", result.suffix
  end

  def test_parse_first_last_comma_suffix_with_roman_numeral
    result = GolfGenius::Scoreboard::NameParser.parse("Wyatt Worthington, II")

    assert_equal "Wyatt", result.first_name
    assert_equal "Worthington", result.last_name
    assert_equal "II", result.suffix
  end

  def test_parse_first_last_comma_suffix_with_middle_name
    result = GolfGenius::Scoreboard::NameParser.parse("Robert F. Gerwin, II")

    assert_equal "Robert F.", result.first_name
    assert_equal "Gerwin", result.last_name
    assert_equal "II", result.suffix
  end

  # Test comma-separated "Last, First" format
  def test_parse_last_first_format
    result = GolfGenius::Scoreboard::NameParser.parse("Christy, Aaron")

    assert_equal "Aaron", result.first_name
    assert_equal "Christy", result.last_name
    assert_nil result.suffix
  end

  def test_parse_last_first_format_with_suffix
    result = GolfGenius::Scoreboard::NameParser.parse("Christy, Aaron Sr.")

    assert_equal "Aaron", result.first_name
    assert_equal "Christy", result.last_name
    assert_equal "Sr.", result.suffix
  end

  def test_parse_last_first_format_with_suffix_no_period
    result = GolfGenius::Scoreboard::NameParser.parse("Christy, Aaron Sr")

    assert_equal "Aaron", result.first_name
    assert_equal "Christy", result.last_name
    assert_equal "Sr.", result.suffix # Normalized to include period
  end

  def test_parse_last_first_format_with_roman_numeral
    result = GolfGenius::Scoreboard::NameParser.parse("Worthington, Wyatt II")

    assert_equal "Wyatt", result.first_name
    assert_equal "Worthington", result.last_name
    assert_equal "II", result.suffix
  end

  def test_parse_last_first_format_with_middle_name
    result = GolfGenius::Scoreboard::NameParser.parse("Gerwin, Robert F.")

    assert_equal "Robert F.", result.first_name
    assert_equal "Gerwin", result.last_name
    assert_nil result.suffix
  end

  def test_parse_last_first_format_with_middle_name_and_suffix
    result = GolfGenius::Scoreboard::NameParser.parse("Gerwin, Robert F. II")

    assert_equal "Robert F.", result.first_name
    assert_equal "Gerwin", result.last_name
    assert_equal "II", result.suffix
  end

  def test_parse_last_first_format_with_amateur_suffix
    result = GolfGenius::Scoreboard::NameParser.parse("Black, Adam (a)")

    assert_equal "Adam", result.first_name
    assert_equal "Black", result.last_name
    assert_nil result.suffix
    assert_equal ["(a)"], result.metadata
    assert_predicate result, :amateur?
  end

  def test_parse_last_first_format_with_suffix_and_amateur
    result = GolfGenius::Scoreboard::NameParser.parse("Gerwin, Robert F. II (a)")

    assert_equal "Robert F.", result.first_name
    assert_equal "Gerwin", result.last_name
    assert_equal "II", result.suffix
    assert_equal ["(a)"], result.metadata
    assert_predicate result, :amateur?
  end
end
