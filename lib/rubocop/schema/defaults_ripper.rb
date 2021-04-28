require 'rubocop/schema/value_objects'

module RuboCop
  module Schema
    class DefaultsRipper
      EXCLUDE_ATTRIBUTES = Set.new(%w[Description VersionAdded VersionChanged StyleGuide]).freeze

      TYPE_MAP = {
        integer: [Integer],
        number:  [Float],
        boolean: [TrueClass, FalseClass],
        string:  [String],
        array:   [Array]
      }.freeze

      # @return [Array<CopInfo>]
      attr_reader :cops

      # @param [Hash] defaults
      def initialize(defaults)
        @cops = defaults.map do |cop_name, attributes|
          CopInfo.new(
            name:               cop_name,
            description:        attributes['Description'],
            enabled_by_default: attributes['Enabled'] == true,
            attributes:         transform_attributes(attributes)
          )
        end
      end

      private

      def transform_attributes(hash)
        hash.map do |name, default|
          next if EXCLUDE_ATTRIBUTES.include? name

          Attribute.new(
            name:    name,
            type:    TYPE_MAP.find { |_, v| v.any? { |c| default.is_a? c } }&.first&.to_s,
            default: default
          )
        end.compact
      end
    end
  end
end
