require 'pathname'
require 'uri'
require 'net/http'

module RuboCop
  class Schema
    class Cache
      # @return [URI]
      attr_reader :base_url

      def initialize(cache_dir, base_url: nil)
        @cache_dir = Pathname(cache_dir)
        @base_url  = validate_url(base_url)
      end

      def get(url)
        url = URI(url)
        url = @base_url + url if @base_url && url.relative?
        validate_url url

        path = path_for_url(url)
        return path.read if path.readable?

        path.parent.mkpath
        Net::HTTP.get(url).tap(&path.method(:write))
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
