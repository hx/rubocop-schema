require 'asciidoctor'
require 'nokogiri'

require 'rubocop/schema/cached_http_client'
require 'rubocop/schema/lockfile_inspector'
require 'rubocop/schema/value_objects'
require 'rubocop/schema/cop_schema'
require 'rubocop/schema/helpers'

module RuboCop
  module Schema
    class Scraper
      include Helpers

      DEFAULT_VERSION = -'master'
      DOCS_URL_TEMPLATE =
        -'https://raw.githubusercontent.com/rubocop/rubocop%s/%s/docs/modules/ROOT/pages/cops%s.adoc'
      DEFAULTS_URL_TEMPLATE =
        -'https://raw.githubusercontent.com/rubocop/rubocop%s/%s/config/default.yml'
      TYPE_MAP = {
        number:  [Numeric],
        boolean: [TrueClass, FalseClass],
        string:  [String],
        array:   [Array]
      }.freeze
      EXCLUDE_ATTRIBUTES = Set.new(%w[Description VersionAdded VersionChanged StyleGuide]).freeze

      # @param [LockfileInspector] lockfile
      # @param [CachedHTTPClient] http_client
      def initialize(lockfile, http_client)
        raise ArgumentError unless http_client.is_a? CachedHTTPClient
        raise ArgumentError unless lockfile.is_a? LockfileInspector

        @http_client = http_client
        @lockfile    = lockfile
      end

      def schema
        template('schema').tap do |json|
          properties = json.fetch('properties')

          lockfile.specs.each do |spec|
            index(spec).each do |department_name|
              dept_info = CopInfo.new(
                name:        department_name,
                description: department_description(spec, department_name)
              )
              properties[department_name] = cop_schema(dept_info)

              info_for(spec, department_name).each do |cop_info|
                properties[cop_info.name] = cop_schema(cop_info)
              end
            end

            defaults(spec)&.each do |cop_name, attributes|
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

      # @return [CachedHTTPClient]
      attr_reader :http_client

      def department_description(spec, department)
        str = "'#{department}' department"
        str << " (#{spec.short_name} extension)" if spec.short_name
        str
      end

      def info_for(spec, department)
        doc = load_doc(extension: spec.short_name, version: spec.version, department: department)
        cop_blocks = doc.query(context: :section) { |s| s.title.start_with? "#{department}/" }
        cop_blocks.map do |section|
          info = CopInfo.new(name: section.title)

          # Stats table
          stats_table_block =
            section
              .query(context: :table) { |t| t.rows.head.first.first.text == 'Enabled by default' }
              .first

          if stats_table_block
            stats_table = table_to_hash(stats_table_block).first
            info.enabled_by_default   = stats_table['Enabled by default'] == 'Enabled'
            info.supports_autocorrect = stats_table['Supports autocorrection'] == 'Yes'
          end

          # Description
          top = section.blocks.index(stats_table_block) || -1
          top += 1
          bottom = section.blocks.index(section.sections.first) || 0
          bottom -= 1
          description = section.blocks[top..bottom].map do |s|
            case s.context
            when :paragraph, :admonition, :listing
              s.lines.join(' ')
            when :literal
              s.lines.map { |l| "  #{l}" }.join("\n")
            when :ulist
              s.blocks.map { |b| " - #{strip_html b.text}" }
            when :olist
              s.blocks.map.with_index { |b, i| "  #{i + 1}. #{strip_html b.text}" }
            when :dlist
              strip_html s.convert # Too hard, just go HTML for now
            else
              raise "Don't know what to do with #{s.context}"
            end
          end

          info.description = description.join("\n\n") unless description.empty?

          # Configurable attributes

          attr_table_block = section
            .query(context: :section) { |s| s.title == 'Configurable attributes' }&.first
            &.query(context: :table)&.first

          if attr_table_block
            info.attributes = table_to_hash(attr_table_block).map do |row|
              type = row['Configurable values']
              Attribute.new(
                name:    row['Name'],
                default: row['Default value'],
                type:    type
              )
            end
          end

          info
        end
      end

      # @param [LockFileInspector::Spec] spec
      def defaults(spec)
        load_defaults extension: spec.short_name, version: spec.version
      end

      def load_defaults(...)
        YAML.safe_load http_client.get(url_for_defaults(...)), permitted_classes: [Regexp, Symbol]
      end

      # @param [LockFileInspector::Spec] spec
      def index(spec)
        doc         = load_doc(extension: spec.short_name, version: spec.version)
        dept_blocks = doc.query(context: :section) { |s| s.title.start_with? 'Department ' }
        dept_blocks.map { |section| link_text section.title }
      end

      def load_doc(...)
        # noinspection RubyResolve
        Asciidoctor.load http_client.get url_for_doc(...)
      end

      def url_for_doc(department: nil, version: DEFAULT_VERSION, extension: nil)
        version = "v#{version}" if version =~ /\A\d+\./
        format(DOCS_URL_TEMPLATE, extension && "-#{extension}", version, department && "_#{department.to_s.downcase}")
      end

      def url_for_defaults(version: DEFAULT_VERSION, extension: nil)
        version = "v#{version}" if version =~ /\A\d+\./
        format(DEFAULTS_URL_TEMPLATE, extension && "-#{extension}", version)
      end

      def link_text(str)
        # The Asciidoctor API doesn't provide access to the raw title, or parts of it.
        # If performance becomes an issue, this could become a regexp or similarly crude solution.
        Nokogiri::HTML(str).at_css('a')&.text
      end

      # Used for stripping HTML from Asciidoctor output, where raw output is not available, or not
      # appropriate to use.
      # TODO: look into the Asciidoctor for a way to do a non-HTML conversion
      def strip_html(str)
        Nokogiri::HTML(str).text
      end

      # @param [Asciidoctor::Table] table
      def table_to_hash(table)
        headings = table.rows.head.first.map(&:text)
        table.rows.body.map do |row|
          headings.each_with_index.to_h do |heading, i|
            [heading, strip_html(row[i].text)]
          end
        end
      end

      # @param [CopInfo] info
      # @return [Hash]
      def cop_schema(info)
        CopSchema.new(info).as_json
      end
    end
  end
end
