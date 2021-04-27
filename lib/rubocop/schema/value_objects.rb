module RuboCop
  module Schema
    CopInfo   = Struct.new(:name, :description, :attributes, :supports_autocorrect, keyword_init: true)
    Attribute = Struct.new(:name, :type, :default, keyword_init: true)
  end
end
