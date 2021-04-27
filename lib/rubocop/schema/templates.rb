module RuboCop
  module Schema
    def self.template(name)
      @templates ||= {}
      (@templates[name] ||= YAML.load_file(ROOT.join('assets', 'templates', "#{name}.yml")).freeze).dup
    end
  end
end
