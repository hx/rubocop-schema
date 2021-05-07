module RuboCop
  module Schema
    CopInfo   = Struct.new(:name, :description, :attributes, :supports_autocorrect, :enabled_by_default)
    Attribute = Struct.new(:name, :type, :default)

    Event = Struct.new(:type, :message) do
      def self.dispatch(**kwargs)
        yield new(**kwargs) if block_given?
      end
    end

    Spec = Struct.new(:name, :version) do
      def short_name
        return nil if name == 'rubocop'

        name[8..-1]
      end

      def to_s
        "#{short_name || name}-#{version}"
      end
    end

    # Support for Ruby 2.4
    module KeywordInitPatch
      def initialize(**attrs)
        super *self.class.members.map { |k| attrs[k] }
      end
    end

    [CopInfo, Attribute, Event, Spec].each { |klass| klass.include KeywordInitPatch }
  end
end
