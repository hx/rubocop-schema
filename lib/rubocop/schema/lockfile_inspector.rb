require 'bundler'
require 'pathname'

module RuboCop
  class Schema
    class LockfileInspector
      Spec = Struct.new(:name, :version, keyword_init: true) do
        def short_name
          return nil if name == 'rubocop'
          name[8..]
        end
      end

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
