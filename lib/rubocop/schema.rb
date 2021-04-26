require 'pathname'
require 'rubocop'

require "rubocop/schema/version"
require "rubocop/schema/cop_schema"
require "rubocop/schema/templates"

module RuboCop
  class Schema
    ROOT = Pathname(__dir__)  # rubocop
             .parent          # lib
             .parent          # root

    # @param [RuboCop::Cop::Registry] registry
    def initialize(registry = RuboCop::Cop::Registry.global)
      @registry = registry
    end

    def as_json
      Schema.template('schema').tap do |json|
        properties = json.fetch('properties')
        # TODO: departments
        @registry.cops.each do |cop|
          properties[cop.cop_name] = CopSchema.new(cop).as_json
        end
      end
    end
  end
end
