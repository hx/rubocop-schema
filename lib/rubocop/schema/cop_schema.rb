require 'rubocop/schema/helpers'

module RuboCop
  module Schema
    class CopSchema
      include Helpers

      KNOWN_TYPES = {
        'boolean' => 'boolean',
        'integer' => 'integer',
        'array'   => 'array',
        'string'  => 'string',
        'float'   => 'number'
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
          prop = props[attr.name] ||= {}
          assign_attribute_type prop, attr
          assign_attribute_description prop, attr
        end
      end

      def assign_default_attributes
        props['AutoCorrect']            = boolean if info.supports_autocorrect
        props['Enabled']['description'] = "Default: #{info.enabled_by_default}" if info.enabled_by_default
      end

      # @param [Hash] prop
      # @param [Attribute] attr
      def assign_attribute_type(prop, attr)
        if KNOWN_TYPES.key? attr.type&.downcase
          prop['type'] ||= KNOWN_TYPES[attr.type.downcase] unless prop.key? '$ref'
        elsif attr.type
          prop['enum'] = attr.type.split(/\s*,\s*/)
        end
      end

      # @param [Hash] prop
      # @param [Attribute] attr
      def assign_attribute_description(prop, attr)
        prop['description'] = format_default(attr.default) unless attr.default.nil?
      end

      def format_default(default)
        default = default.join(', ') if default.is_a? Array
        "Default: #{default}"
      end
    end
  end
end
