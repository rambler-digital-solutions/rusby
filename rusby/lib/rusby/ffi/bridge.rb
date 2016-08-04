module Rusby
  module FFI
    class Bridge
      def self.parameterize(string)
        string.gsub(/\W/, '_').gsub(/_{2,}/, '_').downcase
      end

      def to_ffi(name, value)
        method_name = self.class.parameterize(name + '_to_ffi')
        send(method_name, value)
      end

      def from_ffi(name, value)
        method_name = self.class.parameterize(name + '_from_ffi')
        send(method_name, value)
      end

      def array_fixnum_to_ffi(arg)
        pointer = ::FFI::MemoryPointer.new :int, arg.size
        pointer.put_array_of_int 0, arg
        @size = arg.size
        [pointer, arg.size]
      end

      def array_float_to_ffi(arg)
        pointer = ::FFI::MemoryPointer.new :double, arg.size
        pointer.put_array_of_double 0, arg
        @size = arg.size
        [pointer, arg.size]
      end

      def array_float_from_ffi(result)
        result.read_array_of_double(@size)
      end

      # for arguments which don't need convertion
      def method_missing(_method_name, *args)
        args.first
      end
    end
  end
end
