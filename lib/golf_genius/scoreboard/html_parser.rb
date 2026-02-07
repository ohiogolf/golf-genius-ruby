# frozen_string_literal: true

require "nokogiri"

module GolfGenius
  class Scoreboard
    # Parses HTML tournament results and extracts table structure.
    #
    # This parser is responsible for:
    # - Extracting column metadata from <th> elements
    # - Extracting row data from <tr class='aggregate-row'> elements
    # - Identifying cut lines and cut text
    # - Extracting player metadata (id, name, player_ids, affiliation)
    #
    # The parser returns plain Ruby hashes, not custom objects.
    #
    # @example Parse HTML
    #   parser = GolfGenius::Scoreboard::HtmlParser.new(html_string)
    #   result = parser.parse
    #   # => {
    #   #   columns: [...],
    #   #   rows: [...],
    #   #   cut_text: "The following players did not make match play"
    #   # }
    #
    class HtmlParser
      # @return [String] the HTML to parse
      attr_reader :html

      # Creates a new HTML parser.
      #
      # @param html [String] the HTML to parse
      # @raise [ArgumentError] if html is nil or empty
      #
      def initialize(html)
        raise ArgumentError, "html is required" if html.nil? || html.to_s.strip.empty?

        @html = html
        @doc = Nokogiri::HTML(html)
      end

      # Parses the HTML and returns the table structure.
      #
      # @return [Hash] parsed table structure with :columns, :rows, :cut_text
      #
      def parse
        {
          columns: parse_columns,
          rows: parse_rows,
          cut_text: parse_cut_text,
        }
      end

      private

      # Parses column headers from the HTML table.
      #
      # Extracts metadata from <th> elements in <tr class='header thead'>:
      # - format: from data-format-text or synthesized from CSS class
      # - label: header text with <br/> converted to spaces
      # - round_name: from data-name attribute or CSS class
      #
      # @return [Array<Hash>] array of column hashes
      #
      def parse_columns
        header_row = @doc.css("tr.header.thead").first
        return [] unless header_row

        header_row.css("th").map do |th|
          {
            format: extract_column_format(th),
            label: extract_column_label(th),
            round_name: extract_column_round_name(th),
          }
        end
      end

      # Extracts the format value from a <th> element.
      #
      # Uses data-format-text attribute if present, otherwise synthesizes
      # from CSS class.
      #
      # @param th [Nokogiri::XML::Element] the <th> element
      # @return [String] the format value
      #
      def extract_column_format(th)
        # Check for data-format-text attribute first
        format = th["data-format-text"]
        return format if format && !format.strip.empty?

        # Synthesize from CSS class
        classes = th["class"].to_s.split
        return "position" if classes.include?("pos")
        return "round-total" if classes.include?("past_round_total")

        # Default to "text" if no format can be determined
        "text"
      end

      # Extracts the label text from a <th> element.
      #
      # Replaces <br/> tags with spaces, then collapses whitespace.
      #
      # @param th [Nokogiri::XML::Element] the <th> element
      # @return [String] the label text
      #
      def extract_column_label(th)
        # Replace <br> with space before extracting text, then collapse whitespace
        th_copy = th.dup
        th_copy.css("br").each { |br| br.replace(" ") }
        th_copy.text.gsub(/\s+/, " ").strip
      end

      # Extracts the round name from a <th> element.
      #
      # Checks data-name attribute first, then CSS classes for round indicators.
      #
      # @param th [Nokogiri::XML::Element] the <th> element
      # @return [String, nil] the round name or nil if no round association
      #
      def extract_column_round_name(th)
        # Check data-name attribute
        round_name = th["data-name"]
        return round_name if round_name && !round_name.strip.empty?

        # Check for past_round_ CSS class prefix
        classes = th["class"].to_s.split
        past_round_class = classes.find { |c| c.start_with?("past_round_") }
        if past_round_class
          # Extract round name from label if present
          # (will be matched with round metadata later)
          return nil
        end

        nil
      end

      # Parses player rows from the HTML table.
      #
      # Extracts data from <tr class='aggregate-row'> elements:
      # - id: from data-aggregate-id (integer)
      # - name: from data-aggregate-name (string)
      # - player_ids: from data-member-ids (array of strings)
      # - affiliation: from div.affiliation (string, array, or nil)
      # - cells: array of cell values matching column order
      # - cut: true if row appears after cut line
      #
      # @return [Array<Hash>] array of row hashes
      #
      def parse_rows
        rows = []
        cut_encountered = false

        @doc.css("tr").each do |tr|
          # Check if this is a cut line marker
          if tr["class"].to_s.include?("header") && tr.css("td.cut_list_tr").any?
            cut_encountered = true
            next
          end

          # Skip non-aggregate rows
          next unless tr["class"].to_s.include?("aggregate-row")

          # Skip hidden/spacer rows
          next if tr["class"].to_s.include?("hidden")
          next if tr["style"].to_s.include?("height: 1px")

          rows << {
            id: extract_row_id(tr),
            name: extract_row_name(tr),
            player_ids: extract_row_player_ids(tr),
            affiliation: extract_row_affiliation(tr),
            cells: extract_row_cells(tr),
            cut: cut_encountered,
          }
        end

        rows
      end

      # Extracts the row ID from a row.
      #
      # @param tr [Nokogiri::XML::Element] the <tr> element
      # @return [Integer] the row ID
      # @raise [GolfGenius::ValidationError] if data-aggregate-id attribute is missing
      #
      def extract_row_id(tr)
        id = tr["data-aggregate-id"]
        raise GolfGenius::ValidationError, "Row missing required data-aggregate-id attribute" unless id

        id.to_i
      end

      # Extracts the aggregate name from a row.
      #
      # @param tr [Nokogiri::XML::Element] the <tr> element
      # @return [String] the aggregate name
      #
      def extract_row_name(tr)
        tr["data-aggregate-name"] || ""
      end

      # Extracts the player IDs from a row.
      #
      # @param tr [Nokogiri::XML::Element] the <tr> element
      # @return [Array<String>] array of player ID strings
      #
      def extract_row_player_ids(tr)
        ids = tr["data-member-ids"]
        return [] unless ids && !ids.strip.empty?

        ids.split(",").map(&:strip)
      end

      # Extracts the affiliation from a row.
      #
      # @param tr [Nokogiri::XML::Element] the <tr> element
      # @return [String, Array<String>, nil] affiliation(s) or nil
      #
      def extract_row_affiliation(tr)
        affiliations = tr.css("div.affiliation").map { |div| div.text.strip }
        return nil if affiliations.empty?
        return affiliations.first if affiliations.length == 1

        affiliations
      end

      # Extracts cell values from a row.
      #
      # @param tr [Nokogiri::XML::Element] the <tr> element
      # @return [Array<String>] array of cell values
      #
      def extract_row_cells(tr)
        tr.css("td").map do |td|
          extract_cell_value(td)
        end
      end

      # Extracts the text value from a cell.
      #
      # Removes hidden elements and strips whitespace.
      #
      # @param td [Nokogiri::XML::Element] the <td> element
      # @return [String] the cell value
      #
      def extract_cell_value(td)
        # Remove hidden elements and affiliation divs (affiliation is extracted separately)
        td = td.dup
        td.css("span[style*='display: none']").remove
        td.css("span.hidden").remove
        td.css("div.affiliation").remove

        # Extract text, preferring div.score_to_print if present
        score_div = td.css("div.score_to_print").first
        text = score_div ? score_div.text : td.text

        text.strip
      end

      # Extracts cut line text from the HTML.
      #
      # Looks for <tr class='header'> containing <td class='cut_list_tr'>
      # and returns the text content.
      #
      # @return [String, nil] cut line text or nil if no cut
      #
      def parse_cut_text
        cut_row = @doc.css("tr.header td.cut_list_tr").first
        return nil unless cut_row

        cut_row.text.strip
      end
    end
  end
end
