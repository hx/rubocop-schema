require 'pathname'
require 'json'

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
        fail "Cannot read #{lockfile_path}" unless lockfile_path.readable?
        fail 'RuboCop is not part of this project' unless lockfile.specs.any?

        schema = report_duration { Scraper.new(lockfile, cache).schema }
        puts JSON.pretty_generate schema
      end

      private

      def report_duration
        started  = Time.now
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

      def lockfile
        @lockfile ||= LockfileInspector.new(lockfile_path)
      end

      def lockfile_path
        @lockfile_path ||= @working_dir + 'Gemfile.lock'
      end

      def cache
        @cache ||= Cache.new(cache_dir, &method(:handle_event))
      end

      def cache_dir
        @cache_dir ||= Pathname(Dir.home) + '.rubocop-schema-cache'
      end
    end
  end
end
