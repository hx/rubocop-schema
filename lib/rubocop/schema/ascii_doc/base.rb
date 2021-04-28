module RuboCop
  module Schema
    module AsciiDoc
      class Base
        # @param [Asciidoctor::AbstractBlock] ascii_block
        def initialize(ascii_block)
          @root = ascii_block
          scan
        end

        protected

        # @return [Asciidoctor::Document]
        attr_reader :root

        def scan
          raise NotImplementedError
        end

        def link_text(str)
          # The Asciidoctor API doesn't provide access to the raw title, or parts of it.
          # If performance becomes an issue, this could become a regexp or similarly crude solution.
          Nokogiri::HTML(str).at_css('a')&.text
        end
      end
    end
  end
end
