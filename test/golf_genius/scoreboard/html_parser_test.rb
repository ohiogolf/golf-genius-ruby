# frozen_string_literal: true

require "test_helper"

class HtmlParserTest < Minitest::Test
  def load_fixture(filename)
    File.read(File.join(__dir__, "../../fixtures/tournament_results", filename))
  end

  def test_initialize_requires_html
    error = assert_raises(ArgumentError) do
      GolfGenius::Scoreboard::HtmlParser.new(nil)
    end

    assert_match(/html is required/, error.message)
  end

  def test_initialize_rejects_empty_html
    error = assert_raises(ArgumentError) do
      GolfGenius::Scoreboard::HtmlParser.new("")
    end

    assert_match(/html is required/, error.message)
  end

  def test_parse_returns_hash_structure
    html = "<table><tr class='header thead'></tr></table>"
    parser = GolfGenius::Scoreboard::HtmlParser.new(html)
    result = parser.parse

    assert_kind_of Hash, result
    assert result.key?(:columns)
    assert result.key?(:rows)
    assert result.key?(:cut_text)
  end

  def test_parse_cut_text_returns_nil_when_no_cut
    html = "<table><tr class='header thead'></tr></table>"
    parser = GolfGenius::Scoreboard::HtmlParser.new(html)
    result = parser.parse

    assert_nil result[:cut_text]
  end

  def test_parse_cut_text_extracts_text_from_cut_line
    html = <<~HTML
      <table>
        <tr class='header'>
          <td class='cut_list_tr'>The following players did not make match play</td>
        </tr>
      </table>
    HTML

    parser = GolfGenius::Scoreboard::HtmlParser.new(html)
    result = parser.parse

    assert_equal "The following players did not make match play", result[:cut_text]
  end

  def test_parse_columns_returns_empty_when_no_header
    html = "<table></table>"
    parser = GolfGenius::Scoreboard::HtmlParser.new(html)
    result = parser.parse

    assert_empty result[:columns]
  end

  def test_parse_columns_extracts_format_from_data_attribute
    html = <<~HTML
      <table>
        <tr class='header thead'>
          <th data-format-text='player'>Player</th>
          <th data-format-text='to-par-gross'>To Par</th>
        </tr>
      </table>
    HTML

    parser = GolfGenius::Scoreboard::HtmlParser.new(html)
    result = parser.parse

    assert_equal 2, result[:columns].length
    assert_equal "player", result[:columns][0][:format]
    assert_equal "to-par-gross", result[:columns][1][:format]
  end

  def test_parse_columns_synthesizes_format_from_css_class
    html = <<~HTML
      <table>
        <tr class='header thead'>
          <th class='pos'>Pos.</th>
          <th class='past_round_total'>R1</th>
        </tr>
      </table>
    HTML

    parser = GolfGenius::Scoreboard::HtmlParser.new(html)
    result = parser.parse

    assert_equal 2, result[:columns].length
    assert_equal "position", result[:columns][0][:format]
    assert_equal "round-total", result[:columns][1][:format]
  end

  def test_parse_columns_extracts_label_text
    html = <<~HTML
      <table>
        <tr class='header thead'>
          <th data-format-text='player'>Player Name</th>
          <th data-format-text='thru'>Thru<br/>R2</th>
        </tr>
      </table>
    HTML

    parser = GolfGenius::Scoreboard::HtmlParser.new(html)
    result = parser.parse

    assert_equal 2, result[:columns].length
    assert_equal "Player Name", result[:columns][0][:label]
    assert_equal "Thru R2", result[:columns][1][:label]
  end

  def test_parse_columns_extracts_round_name_from_data_attribute
    html = <<~HTML
      <table>
        <tr class='header thead'>
          <th data-format-text='player'>Player</th>
          <th data-format-text='thru' data-name='R2'>Thru R2</th>
          <th data-format-text='round-total' data-name='R1'>R1</th>
        </tr>
      </table>
    HTML

    parser = GolfGenius::Scoreboard::HtmlParser.new(html)
    result = parser.parse

    assert_equal 3, result[:columns].length
    assert_nil result[:columns][0][:round_name]
    assert_equal "R2", result[:columns][1][:round_name]
    assert_equal "R1", result[:columns][2][:round_name]
  end

  def test_parse_rows_returns_empty_when_no_rows
    html = <<~HTML
      <table>
        <tr class='header thead'>
          <th>Player</th>
        </tr>
      </table>
    HTML

    parser = GolfGenius::Scoreboard::HtmlParser.new(html)
    result = parser.parse

    assert_empty result[:rows]
  end

  def test_parse_rows_extracts_row_metadata
    html = <<~HTML
      <table>
        <tr class='aggregate-row' data-aggregate-id='2185971448' data-aggregate-name='Brian Lefferts' data-member-ids='40208860'>
          <td>1</td>
          <td>Brian Lefferts</td>
        </tr>
      </table>
    HTML

    parser = GolfGenius::Scoreboard::HtmlParser.new(html)
    result = parser.parse

    assert_equal 1, result[:rows].length
    row = result[:rows].first

    assert_equal 2_185_971_448, row[:id]
    assert_equal "Brian Lefferts", row[:name]
    assert_equal ["40208860"], row[:player_ids]
  end

  def test_parse_rows_handles_multiple_player_ids
    html = <<~HTML
      <table>
        <tr class='aggregate-row' data-aggregate-id='123' data-aggregate-name='Team Name' data-member-ids='111, 222, 333'>
          <td>1</td>
          <td>Team Name</td>
        </tr>
      </table>
    HTML

    parser = GolfGenius::Scoreboard::HtmlParser.new(html)
    result = parser.parse

    row = result[:rows].first

    assert_equal %w[111 222 333], row[:player_ids]
  end

  def test_parse_rows_extracts_affiliation
    html = <<~HTML
      <table>
        <tr class='aggregate-row' data-aggregate-id='123' data-aggregate-name='Player Name' data-member-ids='456'>
          <td>1</td>
          <td>
            Player Name
            <div class='affiliation'>Tampa</div>
          </td>
        </tr>
      </table>
    HTML

    parser = GolfGenius::Scoreboard::HtmlParser.new(html)
    result = parser.parse

    row = result[:rows].first

    assert_equal "Tampa", row[:affiliation]
  end

  def test_parse_rows_handles_multiple_affiliations
    html = <<~HTML
      <table>
        <tr class='aggregate-row' data-aggregate-id='123' data-aggregate-name='Team Name' data-member-ids='111,222'>
          <td>1</td>
          <td>
            Team Name
            <div class='affiliation'>Tampa</div>
            <div class='affiliation'>Dublin</div>
          </td>
        </tr>
      </table>
    HTML

    parser = GolfGenius::Scoreboard::HtmlParser.new(html)
    result = parser.parse

    row = result[:rows].first

    assert_equal %w[Tampa Dublin], row[:affiliation]
  end

  def test_parse_rows_extracts_cell_values
    html = <<~HTML
      <table>
        <tr class='aggregate-row' data-aggregate-id='123' data-aggregate-name='Player' data-member-ids='456'>
          <td>1</td>
          <td>Player Name</td>
          <td>+8</td>
          <td>88</td>
        </tr>
      </table>
    HTML

    parser = GolfGenius::Scoreboard::HtmlParser.new(html)
    result = parser.parse

    row = result[:rows].first

    assert_equal ["1", "Player Name", "+8", "88"], row[:cells]
  end

  def test_parse_rows_marks_cut_players
    html = <<~HTML
      <table>
        <tr class='aggregate-row' data-aggregate-id='1' data-aggregate-name='Made Cut' data-member-ids='10'>
          <td>1</td>
          <td>Made Cut</td>
        </tr>
        <tr class='header'>
          <td class='cut_list_tr'>The following players did not make match play</td>
        </tr>
        <tr class='aggregate-row' data-aggregate-id='2' data-aggregate-name='Missed Cut' data-member-ids='20'>
          <td>CUT</td>
          <td>Missed Cut</td>
        </tr>
      </table>
    HTML

    parser = GolfGenius::Scoreboard::HtmlParser.new(html)
    result = parser.parse

    assert_equal 2, result[:rows].length
    assert_equal false, result[:rows][0][:cut]
    assert_equal true, result[:rows][1][:cut]
  end

  def test_parse_rows_skips_hidden_rows
    html = <<~HTML
      <table>
        <tr class='aggregate-row' data-aggregate-id='1' data-aggregate-name='Visible' data-member-ids='10'>
          <td>1</td>
        </tr>
        <tr class='aggregate-row expanded hidden' data-aggregate-id='2' data-aggregate-name='Hidden' data-member-ids='20'>
          <td>-</td>
        </tr>
      </table>
    HTML

    parser = GolfGenius::Scoreboard::HtmlParser.new(html)
    result = parser.parse

    assert_equal 1, result[:rows].length
    assert_equal "Visible", result[:rows][0][:name]
  end

  def test_parse_multi_round_stroke_play_fixture
    html = load_fixture("multi_round_stroke_play.html")
    parser = GolfGenius::Scoreboard::HtmlParser.new(html)
    result = parser.parse

    # Verify columns
    assert_equal 8, result[:columns].length
    assert_equal "position", result[:columns][0][:format]
    assert_equal "Pos.", result[:columns][0][:label]

    assert_equal "player", result[:columns][1][:format]
    assert_equal "Player", result[:columns][1][:label]

    assert_equal "total-to-par-gross", result[:columns][2][:format]
    assert_equal "Total To Par Gross", result[:columns][2][:label]

    assert_equal "thru", result[:columns][3][:format]
    assert_equal "Thru R2", result[:columns][3][:label]

    assert_equal "to-par-gross", result[:columns][4][:format]
    assert_equal "To Par Gross R2", result[:columns][4][:label]
    assert_equal "R2", result[:columns][4][:round_name]

    # Verify rows
    assert_equal 3, result[:rows].length

    # Check first row (Player A)
    first_row = result[:rows][0]

    assert_equal 1001, first_row[:id]
    assert_equal "Player A", first_row[:name]
    assert_equal ["101"], first_row[:player_ids]
    assert_equal "City A", first_row[:affiliation]
    assert_equal false, first_row[:cut]

    # Verify cells
    assert_equal "1", first_row[:cells][0] # position
    assert_equal "Player A", first_row[:cells][1] # player name
    assert_equal "+8", first_row[:cells][2] # total to par gross
    assert_equal "8", first_row[:cells][3] # thru
    assert_equal "-8", first_row[:cells][4] # R2 to par gross

    # Check team row with multiple player_ids and affiliations
    team_row = result[:rows][2]

    assert_equal 1003, team_row[:id]
    assert_equal "Team C", team_row[:name]
    assert_equal %w[103 104], team_row[:player_ids]
    assert_equal ["City C", "City D"], team_row[:affiliation]
    assert_equal "T3", team_row[:cells][0] # tied position
  end

  def test_parse_fixture_with_cut_line
    html = load_fixture("with_cut_line.html")
    parser = GolfGenius::Scoreboard::HtmlParser.new(html)
    result = parser.parse

    # Verify cut text extracted
    assert_equal "The following players did not make match play", result[:cut_text]

    # Verify 3 rows
    assert_equal 3, result[:rows].length

    # Players above cut
    assert_equal false, result[:rows][0][:cut]
    assert_equal false, result[:rows][1][:cut]

    # Player below cut
    assert_equal true, result[:rows][2][:cut]
    assert_equal "CUT", result[:rows][2][:cells][0]
  end
end
