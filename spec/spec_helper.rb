require 'bundler/setup'

require 'vcr'

require 'rubocop'
require 'rubocop-rake'
require 'rubocop-rspec'
require 'rubocop-minitest'
require 'rubocop-performance'
require 'rubocop-rails'

require 'rubocop/schema'
require 'rubocop/schema/cli'

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes/#{RuboCop::Schema::ExtensionSpec.internal}"
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
