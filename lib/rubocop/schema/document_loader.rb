require 'asciidoctor'

module RuboCop
  module Schema
    class DocumentLoader
      DOCS_URL_TEMPLATE =
        -'https://raw.githubusercontent.com/rubocop/%s/%s/docs/modules/ROOT/pages/cops%s.adoc'
      DEFAULTS_URL_TEMPLATE =
        -'https://raw.githubusercontent.com/rubocop/%s/%s/config/default.yml'

      CORRECTIONS = {
        'rubocop' => {
          # Fixes a typo that causes Asciidoctor to crash
          '1.10.0' => '174bda389c2c23cffb17e9d6128f5e6bdbc0e8a0'
        }
      }.freeze

      # @param [CachedHTTPClient] http_client
      def initialize(http_client)
        @http_client = http_client
        @docs        = {}
        @defaults    = {}
      end

      # @param [Spec] spec
      def defaults(spec)
        @defaults[spec] ||=
          YAML.safe_load @http_client.get(url_for_defaults(spec)), [Regexp, Symbol]
      end

      # @param [Spec] spec
      # @param [String] department
      # @return [Asciidoctor::Document]
      def doc(spec, department = nil)
        @docs[[spec, department]] ||=
          Asciidoctor.load @http_client.get url_for_doc(spec, department)
      end

      private

      def url_for_doc(spec, department)
        format DOCS_URL_TEMPLATE, spec.name, correct_version(spec), department && "_#{department.to_s.downcase}"
      end

      def url_for_defaults(spec)
        format DEFAULTS_URL_TEMPLATE, spec.name, correct_version(spec)
      end

      def correct_version(spec)
        CORRECTIONS.dig(spec.name, spec.version) || "v#{spec.version}"
      end
    end
  end
end
