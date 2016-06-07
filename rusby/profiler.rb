require 'benchmark'

module Rusby
  module Profiler
    extend self

    SQRT_ITERATIONS = Math.sqrt(10000).to_i

    def timeit(target_method, *args)
      Benchmark.realtime { SQRT_ITERATIONS.times { target_method.call(*args) } }
    end

    def benchit(original_method, modified_method, args)
      m1 = 0
      m2 = 0

      SQRT_ITERATIONS.times do
        m1 += timeit(original_method, *args)
        m2 += timeit(modified_method, *args)
      end

      boost = (m1 - m2) / m1  * 100

      puts "#{boost.round(2)}% boost"

      boost
    end
  end
end
