#!/usr/bin/env ruby

require 'bundler/setup'
require 'rubocop/schema'
require 'json'

# puts JSON.pretty_generate RuboCop::Schema.new.as_json

lockfile = RuboCop::Schema::LockfileInspector.new('Gemfile.lock')
cache    = RuboCop::Schema::Cache.new('.cache')
scraper  = RuboCop::Schema::Scraper.new(lockfile, cache)
puts JSON.pretty_generate scraper.schema
