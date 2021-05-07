require 'rubocop/schema/value_objects'
require 'rubocop/schema/cop_schema'
require 'rubocop/schema/helpers'
require 'rubocop/schema/ascii_doc/index'
require 'rubocop/schema/ascii_doc/department'
require 'rubocop/schema/document_loader'
require 'rubocop/schema/defaults_ripper'
require 'rubocop/schema/cop_info_merger'

module RuboCop
  module Schema
    class Generator
      include Helpers

      # @return Hash
      attr_reader :schema

      # @param [Array<Spec>] specs
      # @param [DocumentLoader] document_loader
      def initialize(specs, document_loader)
        @specs  = specs
        @loader = document_loader
        @schema = template('schema')
        @props  = @schema.fetch('properties')
        generate
      end

      private

      def generate
        @specs.each &method(:generate_spec)
        @props.delete 'AllCops' unless @specs.any? { |s| s.name == 'rubocop' }
      end

      def generate_spec(spec)
        info_map = read_docs(spec)
        read_defaults(spec).each do |name, cop_info|
          info_map[name] = info_map.key?(name) ? CopInfoMerger.merge(info_map[name], cop_info) : cop_info
        end
        apply_cop_info info_map
      end

      def read_docs(spec)
        {}.tap do |info_map|
          AsciiDoc::Index.new(@loader.doc(spec)).department_names.each do |department|
            info_map[department] = department_info(spec, department)

            AsciiDoc::Department.new(@loader.doc(spec, department)).cops.each do |cop_info|
              info_map[cop_info.name] = CopInfo.new(**cop_info.to_h)
            end
          end
        end
      end

      def read_defaults(spec)
        defaults = @loader.defaults(spec) or
          return {}

        DefaultsRipper.new(defaults).cops.map { |cop_info| [cop_info.name, cop_info] }.to_h
      end

      def apply_cop_info(info)
        info.each do |cop_name, cop_info|
          schema           = CopSchema.new(cop_info).as_json
          @props[cop_name] = @props.key?(cop_name) ? merge_schemas(@props[cop_name], schema) : schema
        end
      end

      # @param [Hash] old
      # @param [Hash] new
      def merge_schemas(old, new)
        deep_merge(old, new) do |merged|
          merged.delete 'type' if merged.key? '$ref'
        end
      end

      # @param [Spec] spec
      # @param [String] department
      # @return [CopInfo]
      def department_info(spec, department)
        description = "'#{department}' department"
        description << " (#{spec.short_name} extension)" if spec.short_name

        CopInfo.new(
          name:        department,
          description: description
        )
      end
    end
  end
end
