require 'byebug'

require './rusby/lazy'
require './rusby/builder'
require './rusby/proxy'

class FanaticPluser
  extend Rusby::Lazy

  rust_method!
  def plusplus(number)
    number + 1
  end
end

pluser = FanaticPluser.new
2.times { pluser.plusplus(1) }
