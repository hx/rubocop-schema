require 'rubocop/schema/helpers'

module RuboCop
  module Schema
    class CopSchema
      include Helpers

      KNOWN_TYPES = Set.new(%w[boolean integer array string]).freeze

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
        if KNOWN_TYPES.include? attr.type.downcase
          prop['type'] = attr.type.downcase
        elsif attr.type != ''
          prop['enum'] = attr.type.split(/\s*,\s*/)
        end
      end
    end
  end
end
