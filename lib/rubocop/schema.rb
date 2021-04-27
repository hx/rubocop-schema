require 'pathname'
require 'rubocop'

require "rubocop/schema/version"
require "rubocop/schema/cache"
require "rubocop/schema/scraper"
require "rubocop/schema/lockfile_inspector"

module RuboCop
  module Schema
    ROOT = Pathname(__dir__)  # rubocop
             .parent          # lib
             .parent          # root
  end
end
