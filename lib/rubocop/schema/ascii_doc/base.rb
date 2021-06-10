require 'rubocop/schema/ascii_doc/stringifier'
require 'rubocop/schema/helpers'

module RuboCop
  module Schema
    module AsciiDoc
      class Base
        include Helpers

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
          str[%r{<a\s.+?>(.+?)</a>}, 1]&.then &method(:strip_html)
        end

        # @param [Asciidoctor::Table] table
        # @return [Array<Hash>] A hash for each row, with table headings as keys
        def table_to_hash(table)
          headings = table.rows.head.first.map(&:text)
          table.rows.body.map do |row|
            headings.each_with_index.map do |heading, i|
              [heading, strip_html(row[i].text)]
            end.to_h
          end
        end

        def stringify_section(section)
          @stringifier ||= Stringifier.new
          @stringifier.stringify section
        end

        def presence(str)
          str unless str.strip == ''
        end
      end
    end
  end
end
