module RuboCop
  module Schema
    CopInfo = Struct.new(
      :name, :description, :attributes, :supports_autocorrect, :enabled_by_default,
      keyword_init: true
    )
    Attribute = Struct.new(:name, :type, :default, keyword_init: true)
    Event     = Struct.new(:type, :message, keyword_init: true)
  end
end
