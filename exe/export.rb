#!/usr/bin/env ruby

require 'bundler/setup'
require 'rubocop/schema'
require 'json'

puts JSON.pretty_generate RuboCop::Schema.new.as_json
