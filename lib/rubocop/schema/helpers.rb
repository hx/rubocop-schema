require 'nokogiri'
require 'uri'
require 'yaml'
require 'net/http'

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

      def deep_merge(old, new, &block)
        return old if old.class != new.class

        case old
        when Hash
          old.merge(new.map { |k, v| [k, old.key?(k) ? deep_merge(old[k], v, &block) : v] }.to_h)
            .tap { |merged| yield merged if block_given? }
        when Array
          old | new
        else
          old
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

      def http_get(url)
        url = URI(url)
        res = Net::HTTP.get_response(url)
        res.body = '' unless res.is_a? Net::HTTPOK
        res.body.force_encoding Encoding::UTF_8
      end
    end
  end
end
