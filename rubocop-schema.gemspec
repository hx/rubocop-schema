require_relative 'lib/rubocop/schema/version'

Gem::Specification.new do |spec|
  spec.name    = 'rubocop-schema-gen'
  spec.version = RuboCop::Schema::VERSION
  spec.authors = ['Neil E. Pearson']
  spec.email   = ['neil@helium.net.au']

  spec.summary     = 'Generate JSON schemas for IDE integration with RuboCop'
  spec.description = spec.summary
  spec.homepage    = 'https://github.com/hx/rubocop-schema'
  spec.license     = 'MIT'

  spec.required_ruby_version = Gem::Requirement.new('>= 2.4.0')

  spec.metadata['homepage_uri']    = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri']   = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").select do |f|
      f.match(%r{^(assets|lib|exe|)/}) || %w[LICENSE README.md].include?(f)
    end
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'asciidoctor', '~> 2.0.14'
end
