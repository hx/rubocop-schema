require 'rubocop/schema/ascii_doc/base'

module RuboCop
  module Schema
    module AsciiDoc
      class Index < Base
        # @return [Array<string>]
        attr_reader :department_names

        protected

        def scan
          @department_names = root
            .query(context: :section) { |s| s.title.start_with? 'Department ' }
            .map { |section| link_text section.title }
        end
      end
    end
  end
end
