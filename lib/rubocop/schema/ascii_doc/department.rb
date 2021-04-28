require 'rubocop/schema/ascii_doc/base'
require 'rubocop/schema/ascii_doc/cop'

module RuboCop
  module Schema
    module AsciiDoc
      class Department < Base
        # @return [Array<Cop>]
        attr_reader :cops

        protected

        def scan
          @cops = root
            .query(context: :section) { |s| s.title.start_with? "#{root.title}/" }
            .map &Cop.method(:new)
        end
      end
    end
  end
end
