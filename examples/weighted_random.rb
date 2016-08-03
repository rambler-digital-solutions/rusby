class WeightedRandom
  extend Rusby::Core

  rusby!
  def pick(weights, seed)
    sum = 0.0
    weightsL = []
    weightsR = []
    weights.each do |weight|
      weightsL << sum
      weightsR << sum + weight
      sum += weight
    end
    number = seed * sum
    weights.each_with_index do |weight, i|
      if (number >= weightsL[i] && number < weightsR[i])
        return i
      end
    end
    return -1
  end
end
