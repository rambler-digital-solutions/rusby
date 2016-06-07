module Rusby
  module Proxy
    extend ::FFI::Library

    def self.libext
      return 'dylib' if `uname` =~ /Darwin/
      return 'so' if `uname` =~ /Linux/
    end

    def self.rusby_load(fullpath)
      ffi_lib "#{fullpath}.#{libext}"
    end
  end
end
