require 'bundler/setup'

require 'vcr'

require 'rubocop'
require 'rubocop-rake'
require 'rubocop-rspec'

require 'rubocop/schema'
require 'rubocop/schema/cli'

module VersionString
  module_function

  FACTORS = [
    RuboCop,
    RuboCop::RSpec,
    RuboCop::Rake
  ].freeze

  def to_s
    factors.join '-'
  end

  def factors
    FACTORS.map do |klass|
      format '%s-%s', klass.name[/\w+\z/].downcase, version_of(klass)
    end
  end

  def version_of(klass)
    if defined? klass::VERSION
      klass::VERSION
    else
      klass::Version::STRING
    end
  end
end

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes/#{VersionString}"
  config.hook_into :webmock
  config.configure_rspec_metadata!
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
