require 'pathname'
require 'rubocop'

require "rubocop/schema/version"
require "rubocop/schema/cop_schema"
require "rubocop/schema/templates"

require 'rubocop/doc_scraper'

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
      scraper = DocScraper.new(cache: ROOT + 'cache')
      Schema.template('schema').tap do |json|
        properties = json.fetch('properties')
        # TODO: departments
        @registry.cops.each do |cop|
          properties[cop.cop_name] = CopSchema.new(cop, scraper.for_cop(cop)).as_json
        end
      end
    end
  end
end
