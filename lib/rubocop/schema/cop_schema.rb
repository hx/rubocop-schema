module RuboCop
  module Schema
    class CopSchema
      # @return [Class<RuboCop::Cop::Base>]
      attr_reader :cop

      # @param [Class<RuboCop::Cop::Base>] cop
      # @param [CopInfo] info
      def initialize(cop, info)
        raise ArgumentError unless cop.is_a?(Class) && cop < Cop::Base
        @cop  = cop
        @info = info
      end

      KNOWN_TYPES = Set.new(%w[boolean integer array string]).freeze

      def as_json
        Schema.template('cop_schema').tap do |json|
          json['$comment']   = cop.documentation_url
          json['properties'] = props = json.fetch('properties').dup

          # AutoCorrect
          props['AutoCorrect'] = { 'type' => 'boolean' } if cop.support_autocorrect?

          if @info
            json['description'] = @info.description
            @info.attributes.each do |attr|
              next if attr.name.blank?

              props[attr.name]    = prop = {}
              prop['description'] = "Default: #{attr.default}" unless attr.default.blank?
              prop['type']        = attr.type if KNOWN_TYPES.include? attr.type
            end
          end
        end
      end
    end
  end
end
