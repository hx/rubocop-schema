require 'json'

require 'rubocop/schema/helpers'
require 'rubocop/schema/diff'
require 'rubocop/schema/extension_spec'
require 'rubocop/schema/value_objects'

module RuboCop
  module Schema
    class Repo
      include Helpers

      # GitHub public APIs have a rate limit of 60/hour when making unauthenticated requests. 100 items
      # per page is the maximum allowed, which we'll use to keep the number of requests to a minimum.
      TAGS_PER_PAGE     = 100
      TAGS_URL_TEMPLATE = -"https://api.github.com/repos/rubocop/%s/tags?page=%d&per_page=#{TAGS_PER_PAGE}"

      def initialize(dir, loader, &event_handler)
        @dir           = Pathname(dir)
        @loader        = loader
        @event_handler = event_handler
        @dir.mkpath
      end

      def build
        ExtensionSpec::KNOWN_GEMS.each &method(:build_for_gem)
        Event.dispatch message: "Repo updated: #{@dir}", &@event_handler
      end

      private

      def build_for_gem(name)
        existing = read(name).map { |h| [h['version'], h['diff']] }.to_h
        previous = nil
        body     = versions_of(name).map do |version|
          previous, diff = fetch_for_spec(Spec.new(name: name, version: version), existing, previous)
          {
            'version' => version,
            'diff'    => diff
          }
        end
        write name, body.compact
      end

      def fetch_for_spec(spec, existing, previous)
        if existing.key? spec.version
          diff   = existing[spec.version]
          schema = Diff.apply(previous, diff)
        else
          schema = build_for_spec(spec)
          diff   = Diff.diff(previous, schema)
        end
        [schema, diff]
      end

      def build_for_spec(spec)
        Event.dispatch message: "Generating: #{spec}", &@event_handler
        Generator.new([spec], @loader).schema
      end

      def write(name, body)
        path_for(name).binwrite JSON.pretty_generate body
      end

      def read(name)
        path = path_for(name)
        return [] unless path.exist?

        JSON.parse path.read
      end

      def path_for(name)
        @dir.join("#{name}.json")
      end

      def versions_of(name)
        tags = []
        loop do
          json = http_get(format(TAGS_URL_TEMPLATE, name, (tags.length / TAGS_PER_PAGE) + 1))
          raise "No tags available for #{name}" if json == ''

          parsed = JSON.parse(json)
          tags += parsed
          break unless parsed.length == TAGS_PER_PAGE
        end

        tags.reverse.map { |obj| obj['name'].to_s[/(?<=\Av)\d.+/] }.compact
      end
    end
  end
end
