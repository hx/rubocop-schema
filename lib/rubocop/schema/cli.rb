require 'pathname'
require 'json'

require 'rubocop/schema/document_loader'
require 'rubocop/schema/cached_http_client'
require 'rubocop/schema/lockfile_inspector'
require 'rubocop/schema/generator'

module RuboCop
  module Schema
    class CLI
      # @param [Pathname] working_dir
      # @param [Hash] env
      # @param [Array<String>] args
      def initialize(working_dir, env, args)
        @working_dir = Pathname(working_dir)
        @env         = env
        @args        = args
      end

      def run
        lockfile_path = @working_dir + 'Gemfile.lock'
        fail "Cannot read #{lockfile_path}" unless lockfile_path.readable?

        lockfile = LockfileInspector.new(lockfile_path)
        fail 'RuboCop is not part of this project' unless lockfile.specs.any?

        schema = report_duration { Generator.new(lockfile.specs, document_loader).schema }
        puts JSON.pretty_generate schema
      end

      private

      def report_duration
        started = Time.now
        yield
      ensure
        finished = Time.now
        handle_event Event.new(message: "Complete in #{(finished - started).round 1}s")
      end

      def handle_event(event)
        case event.type
        when :request
          $stderr << '.'
          @line_dirty = true
        else
          $stderr.puts '' if @line_dirty
          @line_dirty = false
          $stderr.puts event.message.to_s
        end
      end

      def fail(msg)
        $stderr.puts msg.to_s
        exit 1
      end

      def document_loader
        @document_loader ||=
          DocumentLoader.new(
            CachedHTTPClient.new(
              Pathname(Dir.home) + '.rubocop-schema-cache',
              &method(:handle_event)
            )
          )
      end
    end
  end
end
