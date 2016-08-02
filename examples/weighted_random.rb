class WeightedRandom
  extend Rusby::Core

  rusby!
  def pick(weights)
    sum = 0
    weightsL = []
    weightsR = []
    weights.each do |weight|
      weightsL << sum
      weightsR << sum + weight
    end
    sample = rand() * sum
    weights.each_with_index do |weight, i|
      if (sample >= weightsL[i] && sample < weightsR[i])
        return i
      end
    end
    return -1
  end
end
