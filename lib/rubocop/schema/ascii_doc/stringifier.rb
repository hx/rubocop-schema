require 'rubocop/schema/helpers'

module RuboCop
  module Schema
    module AsciiDoc
      class Stringifier
        include Helpers

        # @param [Asciidoctor::Section] section
        def stringify(section)
          method = :"stringify_#{section.context}"
          raise "Don't know what to do with #{section.context}" unless private_methods(false).include? method

          __send__(method, section)
        end

        private

        # @param [Asciidoctor::Section] section
        def stringify_paragraph(section)
          section.lines.join ' '
        end

        alias stringify_admonition stringify_paragraph
        alias stringify_listing stringify_paragraph

        # @param [Asciidoctor::Section] section
        def stringify_literal(section)
          section.lines.map { |l| "  #{l}" }.join "\n"
        end

        # @param [Asciidoctor::Section] section
        def stringify_ulist(section)
          section.blocks.map { |b| " - #{strip_html b.text}" }.join "\n\n" # TODO: single newline
        end

        # @param [Asciidoctor::Section] section
        def stringify_olist(section)
          section.blocks.map.with_index { |b, i| "  #{i + 1}. #{strip_html b.text}" }.join "\n\n" # TODO: single newline
        end

        # @param [Asciidoctor::Section] section
        def stringify_dlist(section)
          strip_html section.convert # Too hard, just go HTML for now
        end
      end
    end
  end
end
