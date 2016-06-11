module Rusby
  module Core
    MIN_BOOST_PERCENT = -50 # heh, have to change the sign

    # DSL
    def rust_method!
      @rusby_awaits_method = true
    end

    private

    def rusby_method_proxy(object, method_name, method_reference, args)
      # just call ruby method and record result
      bound_method = method_reference.bind(object)
      result = bound_method.call(*args)

      # if we are converting recursive function
      # we need to wait for it to exit all recursive calls
      return result if caller.any?{|entry| entry.include?("rusby_method_proxy")}

      rust_method = Builder.convert_to_rust(method_name, method_reference, object, result, *args)

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
    def method_added(name)
      super

      return unless @rusby_awaits_method
      @rusby_awaits_method = false

      original_method = instance_method(name)
      define_method(name) do |*args|
        self.class.send(
          :rusby_method_proxy,
          self,
          name,
          original_method,
          args
        )
      end
    end

    def singleton_method_added(name)
      # TODO
    end
  end
end
