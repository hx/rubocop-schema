module RuboCop
  class Schema
    class CopSchema
      # @return [Class<RuboCop::Cop::Base>]
      attr_reader :cop

      # @param [Class<RuboCop::Cop::Base>] cop
      def initialize(cop)
        raise ArgumentError unless cop.is_a?(Class) && cop < Cop::Base
        @cop = cop
      end

      def as_json
        Schema.template('cop_schema').tap do |json|
          json['$comment']   = cop.documentation_url
          json['properties'] = props = json.fetch('properties').dup

          # AutoCorrect
          props['AutoCorrect'] = { 'type' => 'boolean' } if cop.support_autocorrect?
        end
      end
    end
  end
end
