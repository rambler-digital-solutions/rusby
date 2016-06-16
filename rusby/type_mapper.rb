module Rusby
  class TypeMapper
    def array_fixnum__to_ffi(arg)
      pointer = FFI::MemoryPointer.new :int, arg.size
      pointer.put_array_of_int 0, arg
      @size = arg.size
      [pointer, arg.size]
    end

    def array_fixnum__from_ffi(result)
      result.read_array_of_int(@size)
    end

    def method_missing(_method_name, *args)
      args.first
    end
  end
end
