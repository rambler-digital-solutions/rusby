require 'benchmark'
require 'colorize'
require 'ffi'
require 'hashie'
require 'method_source'
require 'parser/current'
require 'yaml'

rusby_dir = File.expand_path('../rusby', __FILE__)
Dir["#{rusby_dir}/**/*.rb"].each { |file| require file }

module Rusby
end
