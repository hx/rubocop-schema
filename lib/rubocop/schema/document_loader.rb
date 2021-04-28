module RuboCop
  module Schema
    class DocumentLoader
      DOCS_URL_TEMPLATE =
        -'https://raw.githubusercontent.com/rubocop/%s/v%s/docs/modules/ROOT/pages/cops%s.adoc'
      DEFAULTS_URL_TEMPLATE =
        -'https://raw.githubusercontent.com/rubocop/%s/v%s/config/default.yml'

      # @param [CachedHTTPClient] http_client
      def initialize(http_client)
        @http_client = http_client
        @docs        = {}
        @defaults    = {}
      end

      # @param [LockFileInspector::Spec] spec
      def defaults(spec)
        @defaults[spec] ||=
          YAML.safe_load @http_client.get(url_for_defaults(spec)), permitted_classes: [Regexp, Symbol]
      end

      # @param [LockFileInspector::Spec] spec
      # @param [String] department
      # @return [Asciidoctor::Document]
      def doc(spec, department = nil)
        @docs[[spec, department]] ||=
          Asciidoctor.load @http_client.get url_for_doc(spec, department)
      end

      private

      def url_for_doc(spec, department)
        format DOCS_URL_TEMPLATE, spec.name, spec.version, department && "_#{department.to_s.downcase}"
      end

      def url_for_defaults(spec)
        format DEFAULTS_URL_TEMPLATE, spec.name, spec.version
      end
    end
  end
end
