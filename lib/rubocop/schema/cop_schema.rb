require 'rubocop/schema/helpers'

module RuboCop
  module Schema
    class CopSchema
      include Helpers

      KNOWN_TYPES = {
        'Boolean' => 'boolean',
        'Integer' => 'integer',
        'Array'   => 'array',
        'String'  => 'string',
        'Float'   => 'number'
      }.freeze

      # @param [CopInfo] info
      def initialize(info)
        @info = info.dup.freeze
        @json = template('cop_schema')
        generate
      end

      def as_json
        @json
      end

      alias to_h as_json

      def freeze
        @json.freeze
        super
      end

      private

      # @return Hash
      attr_reader :json

      # @return CopInfo
      attr_reader :info

      def props
        json['properties']
      end

      def generate
        json['description'] = info.description unless info.description.nil?
        assign_default_attributes
        info.attributes&.each do |attr|
          assign_attribute props[attr.name] = {}, attr
        end
      end

      def assign_default_attributes
        props['AutoCorrect']            = boolean if info.supports_autocorrect
        props['Enabled']['description'] = "Default: #{info.enabled_by_default}" if info.enabled_by_default
      end

      # @param [Attribute] attr
      def assign_attribute(prop, attr)
        prop['description'] = "Default: #{attr.default}" unless attr.default.blank?
        if KNOWN_TYPES.key? attr.type
          prop['type'] = KNOWN_TYPES[attr.type]
        elsif attr.type != ''
          prop['enum'] = attr.type.split(/\s*,\s*/)
        end
      end
    end
  end
end
