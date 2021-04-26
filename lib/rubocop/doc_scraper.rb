require 'uri'
require 'net/http'
require 'nokogiri'

require 'rubocop/schema/value_objects'

module RuboCop
  class DocScraper
    def initialize(base = 'https://docs.rubocop.org/rubocop/', cache: nil)
      @base = URI(base)
      @pages = {}
      @cache = Pathname(cache) if cache
      load_cache
    end

    # @param [Class<RuboCop::Cop::Base>] klass
    # @return [RuboCop::Schema::CopInfo]
    def for_cop(klass)
      for_badge klass.badge
    end

    # @param [RuboCop::Cop::Badge] badge
    # @return [RuboCop::Schema::CopInfo]
    def for_badge(badge)
      doc = page(badge.department.to_s) or
        return
      section = doc.at_css('article.doc')&.at_xpath(%`div[h2/text()="#{badge}"]`) or
        return

      attrs = section.css('.sect2:has([id^=configurable-attributes]) tbody tr').map do |row|
        name, default, type = *row.css('td').map { |td| td.text.strip }
        Schema::Attribute.new(
          name:    name,
          default: default,
          type:    type.downcase
        )
      end

      Schema::CopInfo.new(
        name:        badge.to_s,
        description: section.css('> .sectionbody > .paragraph').map { |div| div.text.strip.gsub(/\s+/, ' ') }.join("\n\n"),
        attributes:  attrs
      )
    end

    private

    # @return [Pathname]
    attr_reader :cache

    # @param [String] department
    # @return [Nokogiri::XML::Document]
    def page(department)
      @pages[department] ||= fetch_page(department)
    end

    # @param [String] department
    # @return [Nokogiri::XML::Document]
    def fetch_page(department)
      uri = @base + "cops_#{department.gsub(/(?<!\A)(?=[A-Z])/, '_').downcase}.html"
      page = Net::HTTP.get(uri)
      save_to_cache department, page
      read_xml page
    end

    # @param [String] name
    # @param [String] str
    def save_to_cache(name, str)
      return unless cache
      cache.mkpath
      cache.join(name).binwrite str
    end

    def load_cache
      return unless cache&.exist?

      cache.children(false).each do |name|
        path = cache + name
        next unless path.readable?

        @pages[name.to_s] = read_xml(path.binread)
      end
    end

    def read_xml(str)
      Nokogiri::HTML(str)
    end
  end
end
