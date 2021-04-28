require 'asciidoctor'
require 'nokogiri'

require 'rubocop/schema/lockfile_inspector'
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
    class Scraper
      include Helpers

      TYPE_MAP = {
        integer: [Integer],
        number:  [Float],
        boolean: [TrueClass, FalseClass],
        string:  [String],
        array:   [Array]
      }.freeze
      EXCLUDE_ATTRIBUTES = Set.new(%w[Description VersionAdded VersionChanged StyleGuide]).freeze

      # @param [LockfileInspector] lockfile
      # @param [DocumentLoader] document_loader
      def initialize(lockfile, document_loader)
        raise ArgumentError unless document_loader.is_a? DocumentLoader
        raise ArgumentError unless lockfile.is_a? LockfileInspector

        @lockfile = lockfile
        @loader   = document_loader
      end

      def schema
        template('schema').tap do |json|
          properties = json.fetch('properties')

          lockfile.specs.each do |spec|
            info = {}

            AsciiDoc::Index.new(@loader.doc(spec)).department_names.each do |department_name|
              info[department_name] = CopInfo.new(
                name:        department_name,
                description: department_description(spec, department_name)
              )

              AsciiDoc::Department.new(@loader.doc(spec, department_name)).cops.each do |cop_info|
                info[cop_info.name] = CopInfo.new(**cop_info.to_h)
              end
            end

            if (defaults = @loader.defaults(spec))
              DefaultsRipper.new(defaults).cops.each do |cop_info|
                name = cop_info.name
                info[name] = info.key?(name) ? CopInfoMerger.merge(info[name], cop_info) : cop_info
              end
            end

            info.each do |cop_name, cop_info|
              schema = cop_schema(cop_info)
              properties[cop_name] = properties.key?(cop_name) ? merge_schemas(properties[cop_name], schema) : schema
            end
          end
        end
      end

      private

      # @param [Hash] old
      # @param [Hash] new
      def merge_schemas(old, new)
        deep_merge(old, new) do |merged|
          merged.delete 'type' if merged.key? '$ref'
        end
      end

      # @return [LockfileInspector]
      attr_reader :lockfile

      def department_description(spec, department)
        str = "'#{department}' department"
        str << " (#{spec.short_name} extension)" if spec.short_name
        str
      end

      # @param [CopInfo] info
      # @return [Hash]
      def cop_schema(info)
        CopSchema.new(info).as_json
      end
    end
  end
end
