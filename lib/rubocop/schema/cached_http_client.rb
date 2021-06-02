require 'pathname'
require 'uri'

require 'rubocop/schema/helpers'

module RuboCop
  module Schema
    class CachedHTTPClient
      include Helpers

      def initialize(cache_dir, &event_handler)
        @cache_dir     = Pathname(cache_dir)
        @event_handler = event_handler
      end

      def get(url)
        url = URI(url)
        validate_url url

        path = path_for_url(url)
        return path.read if path.readable?

        path.parent.mkpath
        Event.dispatch type: :request, &@event_handler

        http_get(url).tap(&path.method(:write))
      end

      private

      def validate_url(url)
        return if url.nil?

        raise ArgumentError, 'Expected an absolute URL' unless url.absolute?
        raise ArgumentError, 'Expected an HTTP URL' unless url.is_a? URI::HTTP
      end

      # @param [URI::HTTP] url
      def path_for_url(url)
        @cache_dir + url.scheme + url.hostname + url.path[1..-1]
      end
    end
  end
end
