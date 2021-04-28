require 'pathname'
require 'uri'
require 'net/http'

module RuboCop
  module Schema
    class CachedHTTPClient
      # @return [URI]
      attr_reader :base_url

      def initialize(cache_dir, base_url: nil, &event_handler)
        @cache_dir     = Pathname(cache_dir)
        @base_url      = validate_url(base_url)
        @event_handler = event_handler
      end

      def get(url)
        url = URI(url)
        url = @base_url + url if @base_url && url.relative?
        validate_url url

        path = path_for_url(url)
        return path.read if path.readable?

        path.parent.mkpath
        @event_handler&.call Event.new(type: :request)
        Net::HTTP.get(url).force_encoding(Encoding::UTF_8).tap(&path.method(:write))
      end

      private

      def validate_url(url)
        return if url.nil?

        raise ArgumentError, 'Expected an absolute URL' unless url.absolute?
        raise ArgumentError, 'Expected an HTTP URL' unless url.is_a? URI::HTTP

        url
      end

      # @param [URI::HTTP] url
      def path_for_url(url)
        @cache_dir + url.scheme + url.hostname + url.path[1..]
      end
    end
  end
end
