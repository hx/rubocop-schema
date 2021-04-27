require_relative 'lib/rubocop/schema/version'

Gem::Specification.new do |spec|
  spec.name          = "rubocop-schema"
  spec.version       = RuboCop::Schema::VERSION
  spec.authors       = ["Neil E. Pearson"]
  spec.email         = ["neil@helium.net.au"]

  spec.summary       = "Generate JSON schemas for IDE integration with Rubocop"
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/hx/rubocop-schema"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.0.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'rubocop', '~> 1'
  spec.add_dependency 'nokogiri', '~> 1.11'
  spec.add_dependency 'asciidoctor', '~> 2.0.14'
end
