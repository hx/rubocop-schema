require 'rubocop/schema/helpers'

module RuboCop
  module Schema
    class Diff
      include Helpers

      class << self
        def instance
          @instance ||= new
        end

        def diff(old, new)
          instance.diff old, new
        end

        def apply(old, diff)
          instance.apply old, diff
        end
      end

      def diff(old, new)
        return diff_hashes old, new if old.is_a?(Hash) && new.is_a?(Hash)

        new
      end

      def apply(old, diff)
        return apply_hash(old, diff) if old.is_a?(Hash) && diff.is_a?(Hash)

        diff
      end

      private

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

      def apply_hash(old, diff)
        deep_dup(old).tap do |result|
          diff.each do |k, v|
            apply_hash_pair result, k, v
          end
        end
      end

      def apply_hash_pair(hash, key, value)
        if value.nil?
          hash.delete key
        elsif hash.key? key
          hash[key] = apply(hash[key], value)
        else
          hash[key] = value
        end
      end
    end
  end
end
