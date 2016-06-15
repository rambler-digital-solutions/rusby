module Rusby
  module Core
    MIN_BOOST_PERCENT = -50 # heh, have to change the sign

    def rusby!
      @rusby_awaits_method = true
    end

    def rusby_method_proxy(object, method_name, method_reference, args)
      # just call ruby method and record result
      bound_method = method_reference.bind(object)
      result = bound_method.call(*args)

      @rusby_method_table[method_name][:args] = args.map(&:class)
      @rusby_method_table[method_name][:result] = result.class

      unless @rusby_method_table[method_name][:exposed]
        @rusby_method_deaf = true
        define_method(method_name, method_reference)
        return result
      end

      # if we are converting recursive function
      # we need to wait for it to exit all recursive calls
      return result if caller.any? { |entry| entry.include?("'#{method_name}'") }

      rust_method = Builder.convert_to_rust(@rusby_method_table, method_name, method_reference, object)

      boost = Profiler.benchit(bound_method, rust_method, args)
      resulting_method = method_reference
      if boost > MIN_BOOST_PERCENT
        puts "\u2605\u2605\u2605  Running Rust! Yeeeah Baby! \u2605\u2605\u2605"
        resulting_method = ->(*args) { rust_method.call(*args) }
      end

      define_method(method_name, resulting_method)

      result
    end

    # module callbacks
    def method_added(method_name)
      super

      if @rusby_method_deaf
        @rusby_method_deaf = false
        return
      end

      @rusby_method_table ||= {}
      @rusby_method_table[method_name] = {}

      if @rusby_awaits_method
        @rusby_awaits_method = false
        @rusby_method_table[method_name][:exposed] = true
      end

      @rusby_method_deaf = true
      original_method = instance_method(method_name)
      define_method(method_name) do |*args|
        self.class.send(
          :rusby_method_proxy,
          self,
          method_name,
          original_method,
          args
        )
      end
    end

    def singleton_method_added(method_name)
      # TODO
    end
  end
end
