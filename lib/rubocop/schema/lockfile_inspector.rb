require 'bundler'
require 'pathname'

require 'rubocop/schema/value_objects'

module RuboCop
  module Schema
    class LockfileInspector
      KNOWN_GEMS = Set.new(
        %w[
          rubocop
          rubocop-performance
          rubocop-rails
          rubocop-rspec
          rubocop-minitest
          rubocop-rake
          rubocop-sequel
        ]
      )

      # @return [Pathname]
      attr_reader :lockfile_path

      def initialize(lockfile_path)
        @lockfile_path = Pathname(lockfile_path)
      end

      # @return [Array<Spec>]
      def specs
        return [] unless @lockfile_path.readable?

        @specs ||= Bundler::LockfileParser.new(@lockfile_path.to_s).sources.flat_map do |source|
          source.specs.map do |stub|
            next unless KNOWN_GEMS.include? stub.name

            Spec.new(
              name:    stub.name,
              version: stub.version.to_s
            )
          end.compact
        end
      end
    end
  end
end
