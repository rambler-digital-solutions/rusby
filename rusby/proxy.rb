require 'ffi'

module Rusby
  module Proxy
    extend ::FFI::Library

    def self.libext
      return 'dylib' if `uname` =~ /Darwin/
      return 'so' if `uname` =~ /Linux/
    end

    def self.rusby_load(name)
      root_path = "#{File.dirname(__FILE__)}/../lib"
      ffi_lib "#{root_path}/#{name}.#{libext}"
    end
  end
end
