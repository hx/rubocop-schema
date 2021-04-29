module RuboCop
  module Schema
    class CopInfoMerger
      # @param [CopInfo] old
      # @param [CopInfo] new
      # @return [CopInfo]
      def self.merge(old, new)
        new(old, new).merged
      end

      # @return [CopInfo]
      attr_reader :merged

      def initialize(old, new)
        @merged = old.dup
        @new = new
        merge
      end

      private

      def merge
        @merged.supports_autocorrect = @new.supports_autocorrect if @merged.supports_autocorrect.nil?
        @merged.enabled_by_default   = @new.enabled_by_default if @merged.enabled_by_default.nil?
        @merged.attributes           = merge_attribute_sets(@merged.attributes, @new.attributes)
        @merged.description          ||= @new.description
      end

      # @param [Array<Attribute>] old
      # @param [Array<Attribute>] new
      # @return [Array<Attribute>]
      def merge_attribute_sets(old, new)
        return old || new unless old && new

        merged = old.map { |attr| [attr.name, attr] }.to_h
        new.each do |attr|
          merged[attr.name] = merged.key?(attr.name) ? merge_attributes(merged[attr.name], attr) : attr
        end

        merged.values
      end

      # @param [Attribute] old
      # @param [Attribute] new
      # @return [Attribute]
      def merge_attributes(old, new)
        old.dup.tap do |merged|
          merged.type    ||= new.type
          merged.default ||= new.default
        end
      end
    end
  end
end
