require 'benchmark'

module Rusby
  module Profiler
    extend self

    SQRT_ITERATIONS = Math.sqrt(1000).to_i

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

        percent = ((i + 1).to_f / SQRT_ITERATIONS * 100).to_i
        print "\r|#{'=' * percent}#{'-' * (100 - percent)}|"
      end

      boost = m1 > m2 ? m1 / m2 : - m2 / m1

      printf "\r=> got #{'%.2fx boost'.colorize(boost > 0 ? :green : :red)} (%.2fs original vs %.2fs rust) %s\n\n", boost, m1, m2, ' ' * 80

      boost
    end
  end
end
