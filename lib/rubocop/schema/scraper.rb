require 'asciidoctor'
require 'nokogiri'

require 'rubocop/schema/lockfile_inspector'
require 'rubocop/schema/value_objects'
require 'rubocop/schema/cop_schema'
require 'rubocop/schema/helpers'
require 'rubocop/schema/ascii_doc/index'
require 'rubocop/schema/ascii_doc/department'
require 'rubocop/schema/document_loader'

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
            AsciiDoc::Index.new(@loader.doc(spec)).department_names.each do |department_name|
              dept_info = CopInfo.new(
                name:        department_name,
                description: department_description(spec, department_name)
              )
              properties[department_name] = cop_schema(dept_info)

              AsciiDoc::Department.new(@loader.doc(spec, department_name)).cops.each do |cop_info|
                properties[cop_info.name] = cop_schema(cop_info)
              end
            end

            @loader.defaults(spec)&.each do |cop_name, attributes|
              cop = properties[cop_name] ||= cop_schema(CopInfo.new(name: cop_name))
              cop['description'] ||= attributes['Description'] if attributes['Description']
              cop['description'] ||= department_description(spec, cop_name) unless cop_name.include?('/')
              attributes.each do |attr_name, attr_default|
                next if EXCLUDE_ATTRIBUTES.include? attr_name

                attr = cop['properties'][attr_name] ||= {}
                attr['type'] ||= TYPE_MAP.find { |_, v| v.any? { |c| attr_default.is_a? c } }&.first unless attr['$ref']
                unless attr_default.nil?
                  attr['description'] = "Default: #{attr_default.is_a?(Array) ? attr_default.join(', ') : attr_default}"
                end
                attr.compact!
              end
            end
          end
        end
      end

      private

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
