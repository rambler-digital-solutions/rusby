module Rusby
  module Core
    MIN_BOOST_PERCENT = -50 # heh, have to change the sign

    # next method should be added to the rusby table
    def rusby!
      @rusby_awaits_method = true
    end

    def rusby_replace_method(method_name, method_reference)
      @rusby_skips_method = true
      define_method(method_name, method_reference)
    end

    # proxy method that records arg and result types
    def rusby_method_proxy(object, method_name, method_reference, args)
      bound_method = method_reference.bind(object)
      result = bound_method.call(*args)

      @rusby_method_table[method_name][:args] = args.map(&:class)
      @rusby_method_table[method_name][:result] = result.class

      unless @rusby_method_table[method_name][:exposed]
        # if we don't need to convert method to rust return back the original method
        rusby_replace_method(method_name, method_reference)
      else
        # try to convert to rust or return back the original method
        rusby_convert_or_bust(method_name, method_reference, object, args)
      end

      result
    end

    def rusby_convert_or_bust(method_name, method_reference, object, args)
      # if we are converting recursive function
      # we need to wait for it to exit all recursive calls
      return if caller.any? { |entry| entry.include?("'#{method_name}'") }

      rust_method = Builder.convert_to_rust(
        @rusby_method_table,
        method_name,
        method_reference,
        object
      )

      # check if rust method is running faster than the original one
      boost = Profiler.benchit(method_reference.bind(object), rust_method, args)

      # coose between rust and ruby methods
      resulting_method = method_reference
      if boost > MIN_BOOST_PERCENT
        puts "\u2605\u2605\u2605  Running Rust! Yeeeah Baby! \u2605\u2605\u2605"
        resulting_method = ->(*args) { rust_method.call(*args) }
      end

      # set chosen method permanently
      rusby_replace_method(method_name, resulting_method)
    end

    # module callbacks
    def method_added(method_name)
      super

      if @rusby_skips_method
        @rusby_skips_method = false
        return
      end

      @rusby_method_table ||= {}
      @rusby_method_table[method_name] = {}

      if @rusby_awaits_method
        @rusby_awaits_method = false
        @rusby_method_table[method_name][:exposed] = true
      end

      @rusby_skips_method = true
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
