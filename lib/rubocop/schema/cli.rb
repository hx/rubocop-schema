require 'pathname'
require 'json'

require 'rubocop/schema/document_loader'
require 'rubocop/schema/cached_http_client'
require 'rubocop/schema/generator'
require 'rubocop/schema/extension_spec'
require 'rubocop/schema/repo'

module RuboCop
  module Schema
    class CLI
      # @param [Pathname] working_dir
      # @param [Hash] env
      # @param [Array<String>] args
      # @param [String] home
      # @param [IO] out_file
      # @param [IO] log_file
      def initialize(working_dir: Dir.pwd, env: ENV, args: ARGV, home: Dir.home, out_file: nil, log_file: $stderr)
        @working_dir = Pathname(working_dir)
        @home_dir    = Pathname(home)
        @env         = env
        @args        = args
        @out_file    = out_file
        @log_file    = log_file

        raise ArgumentError, 'Cannot accept an out_file and an argument' if @out_file && args.first
      end

      def run
        read_flag while @args.first&.start_with?('--')
        assign_outfile

        print "Generating #{@out_path} … " if @out_path

        schema = report_duration(lowercase: @out_path) { Generator.new(spec.specs, document_loader).schema }
        @out_file.puts JSON.pretty_generate schema
      end

      private

      def read_flag
        case @args.shift
        when '--version'
          info VERSION
        when '--spec'
          info spec
        when /\A--spec=(\S+)/
          @spec = ExtensionSpec.from_string($1)
        when /\A--build-repo=(.+)/
          build_repo $1
        end
      end

      def build_repo(dir)
        Repo.new(dir, document_loader, &method(:handle_event)).build
        exit
      end

      def spec
        @spec ||=
          begin
            lockfile_path = @working_dir + 'Gemfile.lock'
            fail "Cannot read #{lockfile_path}" unless lockfile_path.readable?

            spec = ExtensionSpec.from_lockfile(lockfile_path)
            fail 'RuboCop is not part of this project' if spec.empty?

            spec
          end
      end

      def assign_outfile
        return if @out_file

        @out_path = path_from_arg(@args.first)

        @out_file ||= File.open(@out_path, 'w') # rubocop:disable Naming/MemoizedInstanceVariableName
      end

      def path_from_arg(arg)
        case arg
        when '-'
          @out_file = $stdout
          nil
        when nil
          "#{spec}-config-schema.json"
        else
          arg
        end
      end

      def report_duration(lowercase: false)
        started = Time.now
        yield
      ensure
        finished = Time.now
        message  = "Complete in #{(finished - started).round 1}s"
        message.downcase! if lowercase
        handle_event Event.new(message: message)
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

      def info(msg)
        $stdout.puts msg
        exit
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
