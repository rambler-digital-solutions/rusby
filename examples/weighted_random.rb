class WeightedRandom
  extend Rusby::Core

  rusby!
  def pick(weights, seed)
    sum = 0.0
    left_bounds = []
    right_bounds = []
    weights.each do |item|
      left_bounds << sum
      sum = sum + item
      right_bounds << sum
    end
    number = seed * sum
    weights.each_with_index do |_, i|
      if (number >= left_bounds[i] && number < right_bounds[i])
        return i
      end
    end
    return -1
  end
end
