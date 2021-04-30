require 'rubocop/schema/value_objects'

module RuboCop
  module Schema
    class ExtensionSpec
      KNOWN_CLASSES = Set.new(
        %w[
          RuboCop
          RuboCop::Rake
          RuboCop::RSpec
          RuboCop::Minitest
          RuboCop::Performance
          RuboCop::Rails
        ]
      ).freeze

      KNOWN_GEMS = Set.new(['rubocop', *KNOWN_CLASSES.map { |e| e.sub('::', '-').downcase }]).freeze

      def self.internal
        @internal ||= new(KNOWN_CLASSES.map do |klass_name|
          next unless Object.const_defined? klass_name

          klass = Object.const_get(klass_name)
          Spec.new(
            name:    klass.name.sub('::', '-').downcase,
            version: (defined?(klass::VERSION) ? klass::VERSION : klass::Version::STRING)
          )
        end.compact)
      end

      def self.from_lockfile(lockfile)
        new(Bundler::LockfileParser.new(lockfile.to_s).sources.flat_map do |source|
          source.specs.map do |stub|
            next unless KNOWN_GEMS.include? stub.name

            Spec.new(
              name:    stub.name,
              version: stub.version.to_s
            )
          end.compact
        end)
      end

      attr_reader :specs

      def initialize(specs)
        @specs = specs.dup.sort_by(&:name).freeze
      end

      def to_s
        @specs.join '-'
      end

      def empty?
        @specs.empty?
      end
    end
  end
end
