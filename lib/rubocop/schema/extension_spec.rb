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

      # @param [Pathname] lockfile
      def self.from_lockfile(lockfile)
        new(lockfile.readlines.map do |line|
          next unless line =~ /\A\s+(rubocop(?:-\w+)?) \((\d+(?:\.\d+)+)\)\s*\z/
          next unless KNOWN_GEMS.include? $1

          Spec.new(name: $1, version: $2)
        end.compact)
      end

      def self.from_string(string)
        new(string.split('-').each_slice(2).map do |(name, version)|
          name = "rubocop-#{name}" unless name == 'rubocop'

          raise ArgumentError, "Unknown gem '#{name}'" unless KNOWN_GEMS.include? name
          raise ArgumentError, "Invalid version '#{version}'" unless version&.match? /\A\d+(?:\.\d+)+\z/

          Spec.new(name: name, version: version)
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
