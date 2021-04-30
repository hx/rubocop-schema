require 'pathname'
require 'json'

require 'rubocop/schema/document_loader'
require 'rubocop/schema/cached_http_client'
require 'rubocop/schema/generator'
require 'rubocop/schema/extension_spec'

module RuboCop
  module Schema
    class CLI
      # @param [Pathname] working_dir
      # @param [Hash] env
      # @param [Array<String>] args
      # @param [String] home
      # @param [IO] out_file
      # @param [IO] log_file
      def initialize(working_dir: Dir.pwd, env: ENV, args: ARGV, home: Dir.home, out_file: $stdout, log_file: $stderr)
        @working_dir = Pathname(working_dir)
        @home_dir    = Pathname(home)
        @env         = env
        @args        = args
        @out_file    = out_file
        @log_file    = log_file
      end

      def run
        lockfile_path = @working_dir + 'Gemfile.lock'
        fail "Cannot read #{lockfile_path}" unless lockfile_path.readable?

        specs = ExtensionSpec.from_lockfile(lockfile_path).specs
        fail 'RuboCop is not part of this project' unless specs.any?

        schema = report_duration { Generator.new(specs, document_loader).schema }
        @out_file.puts JSON.pretty_generate schema
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
          @log_file << '.'
          @line_dirty = true
        else
          @log_file.puts '' if @line_dirty
          @line_dirty = false
          @log_file.puts event.message.to_s
        end
      end

      def fail(msg)
        @log_file.puts msg.to_s
        exit 1
      end

      def document_loader
        @document_loader ||=
          DocumentLoader.new(
            CachedHTTPClient.new(
              @home_dir + '.rubocop-schema-cache',
              &method(:handle_event)
            )
          )
      end
    end
  end
end
