module RuboCop
  module Schema
    module Helpers
      def self.templates
        @templates ||= {}
      end

      def deep_dup(obj)
        case obj
        when String
          obj.dup
        when Hash
          obj.transform_values &method(:deep_dup)
        when Array
          obj.map &method(:deep_dup)
        else
          obj
        end
      end

      def boolean
        { 'type' => 'boolean' }
      end

      def template(name)
        deep_dup(Helpers.templates[name] ||= YAML.load_file(ROOT.join('assets', 'templates', "#{name}.yml")).freeze)
      end

      # Used for stripping HTML from Asciidoctor output, where raw output is not available, or not
      # appropriate to use.
      # TODO: look into the Asciidoctor for a way to do a non-HTML conversion
      def strip_html(str)
        Nokogiri::HTML(str).text
      end
    end
  end
end
