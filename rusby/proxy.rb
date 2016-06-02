require "fiddle"
require "fiddle/import"

module Rusby
  module Proxy
    extend Fiddle::Importer

    def self.libext
      return "dylib" if `uname` =~ /Darwin/
      return "so" if `uname` =~ /Linux/
    end

    def self.rusby_load(name)
      dlload "./lib/#{name}.#{libext}"
    end
  end
end
