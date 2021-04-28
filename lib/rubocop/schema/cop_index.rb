module RuboCop
  module Schema
    class CopIndex
      # @param [Asciidoctor::Document] ascii_doc
      def initialize(ascii_doc)
        @doc = ascii_doc
      end

      def department_names
        @department_names ||= scan_department_names
      end

      private

      def scan_department_names
        dept_blocks = @doc.query(context: :section) { |s| s.title.start_with? 'Department ' }
        dept_blocks.map { |section| link_text section.title }
      end

      def link_text(str)
        # The Asciidoctor API doesn't provide access to the raw title, or parts of it.
        # If performance becomes an issue, this could become a regexp or similarly crude solution.
        Nokogiri::HTML(str).at_css('a')&.text
      end
    end
  end
end
