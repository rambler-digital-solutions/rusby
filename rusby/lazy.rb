require 'benchmark/ips'
require 'ruby-prof'
require 'benchmark'

def benchit
  Benchmark.ips do |x|
    x.time = 3
    x.warmup = 1
    x.report('yield') { yield }
    x.compare!
  end
end

def stopwatch_start
end

def stopwatch_stop
end

def timeit
  RubyProf.start
  1e5.to_i.times { yield }
  result = RubyProf.stop
  printer = RubyProf::FlatPrinter.new(result)
  printer.print(STDOUT)
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

          start = Time.now
          1_000_000.times { bound_method.call(*args) }
          finish = Time.now
          puts finish - start

          convertion_result = self.class.convert_to_rust(name, orig_method, result, *args)
          result
        else
          puts "-> second run of #{name}"
          puts "\u2605\u2605\u2605  Running Rust! Yeeeah Baby! \u2605\u2605\u2605"

          start = Time.now
          1_000_000.times { Proxy.send(name, *args) }
          finish = Time.now
          puts finish - start

          # puts "NOOOO!!! #{Fiddle.last_error}" if Fiddle.last_error
          # raise SystemCallError.new(Fiddle.last_error)
          Proxy.send(name, *args)
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
      puts `rustc --crate-type=dylib -O -o #{root_path}/#{name}.dylib #{root_path}/#{name}.rs`
      # puts `ls -al #{root_path}/#{name}.dylib`

      Proxy.rusby_load name
      Proxy.attach_function name, [:int], :int

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
