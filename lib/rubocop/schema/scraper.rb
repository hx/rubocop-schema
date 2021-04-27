require 'asciidoctor'
require 'nokogiri'

require 'rubocop/schema/cache'
require 'rubocop/schema/lockfile_inspector'
require 'rubocop/schema/templates'
require 'rubocop/schema/value_objects'

module RuboCop
  module Schema
    class Scraper
      DEFAULT_VERSION = -'master'
      URL_TEMPLATE    =
        -'https://raw.githubusercontent.com/rubocop/rubocop%s/%s/docs/modules/ROOT/pages/cops%s.adoc'

      # @param [LockfileInspector] lockfile
      # @param [Object] cache
      def initialize(lockfile, cache)
        raise ArgumentError unless cache.is_a? Cache
        raise ArgumentError unless lockfile.is_a? LockfileInspector

        @cache    = cache
        @lockfile = lockfile
      end

      def schema
        Schema.template('schema').tap do |json|
          properties = json.fetch('properties')

          lockfile.specs.each do |spec|
            index(spec).each do |department_name|
              dept_info = CopInfo.new(
                name: department_name,
                description: "Department #{department_name}"
              )
              dept_info.description << " (#{spec.short_name} extension)" if spec.short_name
              properties[department_name] = cop_schema(dept_info)

              info_for(spec, department_name).each do |cop_info|
                properties[cop_info.name] = cop_schema(cop_info)
              end
            end
          end
        end
      end

      private

      # @return [LockfileInspector]
      attr_reader :lockfile

      # @return [Cache]
      attr_reader :cache

      def info_for(spec, department)
        doc = load_doc(extension: spec.short_name, version: spec.version, department: department)
        cop_blocks = doc.query(context: :section) { |s| s.title.start_with? "#{department}/" }
        cop_blocks.map do |section|
          info = CopInfo.new(name: section.title)

          description = []
          # Stats table
          if (stats_table_block = section.query(context: :table) { |t| t.rows.head.first.first.text == 'Enabled by default' }.first)
            stats_table = table_to_hash(stats_table_block).first
            description << "Default: #{stats_table['Enabled by default']}"
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
              s.blocks.map { |b| " - #{reverse_html b.text}" }
            when :olist
              s.blocks.map.with_index { |b, i| "  #{i+1}. #{reverse_html b.text}" }
            when :dlist
              reverse_html s.convert # Too hard, just go HTML for now
            else
              raise "Don't know what to do with #{s.context}"
            end
          end + description

          info.description = description.join("\n\n") unless description.empty?

          # Configurable attributes

          attr_table_block =
            section
              .query(context: :section) { |s| s.title == 'Configurable attributes' }&.first
              &.query(context: :table)&.first

          if attr_table_block
            info.attributes = table_to_hash(attr_table_block).map do |row|
              type = row['Configurable values']
              type = type.scan(/\w+/) if type.start_with? '`'
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
      def index(spec)
        doc         = load_doc(extension: spec.short_name, version: spec.version)
        dept_blocks = doc.query(context: :section) { |s| s.title.start_with? 'Department ' }
        dept_blocks.map { |section| link_text section.title }
      end

      def load_doc(...)
        #noinspection RubyResolve
        Asciidoctor.load cache.get url_for(...)
      end

      def url_for(department: nil, version: DEFAULT_VERSION, extension: nil)
        version = "v#{version}" if version =~ /\A\d+\./
        URL_TEMPLATE % [
          extension && "-#{extension}",
          version,
          department && "_#{department.to_s.downcase}"
        ]
      end

      def link_text(str)
        # The Asciidoctor API doesn't provide access to the raw title, or parts of it.
        # If performance becomes an issue, this could become a regexp or similarly crude solution.
        Nokogiri::HTML(str).at_css('a')&.text
      end

      def reverse_html(str)
        str = str.gsub(%r{</?code>}, '`')
        Nokogiri::HTML(str).text
      end

      # @param [Asciidoctor::Table] table
      def table_to_hash(table)
        headings = table.rows.head.first.map(&:text)
        table.rows.body.map do |row|
          headings.each_with_index.to_h do |heading, i|
            [heading, reverse_html(row[i].text)]
          end
        end
      end

      KNOWN_TYPES = Set.new(%w[boolean integer array string]).freeze

      # @param [CopInfo] info
      def cop_schema(info)
        Schema.template('cop_schema').tap do |json|
          json['description'] = info.description
          json['properties'] = props = json.fetch('properties').dup

          props['AutoCorrect'] = { 'type' => 'boolean' } if info.supports_autocorrect

          info.attributes&.each do |attr|
            props[attr.name] = prop = {}
            prop['description'] = "Default: #{attr.default}" unless attr.default.blank?
            case attr.type
            when Array
              prop['enum'] = attr.type
            when String
              type = attr.type.downcase
              prop['type'] = type if KNOWN_TYPES.include? type
            end
          end
        end
      end
    end
  end
end
