require 'benchmark'

module Rusby
  module Profiler
    extend self

    SQRT_ITERATIONS = Math.sqrt(100).to_i

    def timeit(target_method, *args)
      Benchmark.realtime { SQRT_ITERATIONS.times { target_method.call(*args) } }
    end

    def benchit(obj, original_method, modified_method, args)
      original_method = original_method.bind(obj)

      m1 = 0
      m2 = 0

      SQRT_ITERATIONS.times do |i|
        m1 += timeit(original_method, *args)
        m2 += timeit(modified_method, *args)
        puts "#{i + 1} of #{SQRT_ITERATIONS} done."
      end

      boost = m1 / m2

      printf "\n\n%.2fx boost (%.2f vs %.2f)\n\n", boost, m1, m2

      boost
    end
  end
end
