require 'rubocop/schema/helpers'

module RuboCop
  module Schema
    module Diff
      extend Helpers

      module_function

      def diff(old, new)
        return diff_hashes old, new if old.is_a?(Hash) && new.is_a?(Hash)

        new
      end

      def diff_hashes(old, new)
        (old.keys - new.keys).map { |k| [k, nil] }.to_h.tap do |result|
          new.each do |k, v|
            if old.key? k
              result[k] = diff(old[k], v) unless old[k] == v
            else
              result[k] = v
            end
          end
        end
      end

      def apply(old, diff)
        return apply_hash(old, diff) if old.is_a?(Hash) && diff.is_a?(Hash)

        diff
      end

      def apply_hash(old, diff)
        deep_dup(old).tap do |result|
          diff.each do |k, v|
            if v.nil?
              result.delete k
            elsif result.key? k
              result[k] = apply(result[k], v)
            else
              result[k] = v
            end
          end
        end
      end
    end
  end
end
