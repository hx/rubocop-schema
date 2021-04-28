require 'rubocop/schema/ascii_doc/base'
require 'rubocop/schema/value_objects'

module RuboCop
  module Schema
    module AsciiDoc
      class Cop < Base
        # @return [String]
        attr_reader :name

        # @return [String]
        attr_reader :description

        # @return [TrueClass, FalseClass]
        attr_reader :enabled_by_default

        # @return [TrueClass, FalseClass]
        attr_reader :supports_autocorrect

        # @return [Array<Attribute>]
        attr_reader :attributes

        def to_h
          (public_methods(false) - [:to_h]).to_h { |k| [k, __send__(k)] }
        end

        protected

        def scan
          @name = root.title
          read_stats_table
          read_description
          read_attributes
        end

        private

        def read_stats_table
          return unless stats_table

          @enabled_by_default   = stats_table['Enabled by default'] == 'Enabled'
          @supports_autocorrect = stats_table['Supports autocorrection'] == 'Yes'
        end

        def read_description
          blocks       = root.blocks[find_description_range]
          @description = blocks.map(&method(:stringify_section)).join("\n\n") if blocks.any?
        end

        def read_attributes
          return unless attr_table_block

          @attributes = table_to_hash(attr_table_block).map do |row|
            Attribute.new(
              name:    row['Name'],
              default: presence(row['Default value']),
              type:    presence(row['Configurable values'])
            )
          end
        end

        def find_description_range
          top    = stats_table_block ? root.blocks.index(stats_table_block) + 1 : 0
          bottom = root.blocks.index(root.sections.first) || 0
          top..(bottom - 1)
        end

        # @return [Asciidoctor::Block, nil]
        def stats_table_block
          @stats_table_block ||= root
            .query(context: :table) { |t| t.rows.head.first.first.text == 'Enabled by default' }
            .first
        end

        # @return [Asciidoctor::Block, nil]
        def attr_table_block
          @attr_table_block ||= root
            .query(context: :section) { |s| s.title == 'Configurable attributes' }
            &.first
            &.query(context: :table)
            &.first
        end

        # @return [Array<Hash>, nil]
        def stats_table
          @stats_table ||= stats_table_block && table_to_hash(stats_table_block).first
        end
      end
    end
  end
end
