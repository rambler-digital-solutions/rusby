require 'benchmark/ips'

def timeit
  Benchmark.ips do |x|
    x.time = 10
    x.warmup = 2
    x.report('yield') { yield }
    x.compare!
  end
end

module Rusby
  module Lazy
    def method_added(name)
      super

      @rusby_awaits_method ? @rusby_awaits_method = false : return

      orig_method = instance_method(name)

      instance_variable_set("@rusby_watches_#{name}", true)

      define_method(name) do |*args|
        if self.class.instance_variable_get("@rusby_watches_#{name}")
          puts "-> first run of #{name}"
          self.class.instance_variable_set("@rusby_watches_#{name}", false)
          bound_method = orig_method.bind(self)
          result = bound_method.call(*args)

          timeit { bound_method.call(*args) }

          convertion_result = self.class.convert_to_rust(name, orig_method, result, *args)
          result
        else
          puts "-> second run of #{name}"
          puts "\u2605\u2605\u2605  Running Rust! Yeeeah Baby! \u2605\u2605\u2605"

          timeit { Proxy.send(name, *args) }

          puts Proxy.send(name, *args)
        end
      end
    end

    def convert_to_rust(name, orig_method, result, *args)
      ast = Parser::CurrentRuby.parse(orig_method.source)
      signature, code = Builder.method_to_rust(ast, args.map(&:class), result.class)
      instance_variable_set("@rusby_runs_#{name}", signature)
      root_path = "#{File.dirname(__FILE__)}/../lib"
      File.open("#{root_path}/#{name}.rs", 'w') do |file|
        file.write(code)
      end

      puts "Compiling #{signature}..."
      `rustc --crate-type=dylib -o #{root_path}/#{name}.dylib #{root_path}/#{name}.rs`

      Proxy.rusby_load name
      Proxy.extern signature

      signature
    end

    def rust_method!
      @rusby_awaits_method = true
    end

    def singleton_method_added(name)
      # TODO
    end
  end
end
