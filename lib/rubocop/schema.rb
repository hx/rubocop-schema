require 'pathname'

require 'rubocop/schema/version'

module RuboCop
  module Schema
    ROOT =
      Pathname(__dir__) # rubocop/
        .parent         # lib/
        .parent         # /
  end
end
