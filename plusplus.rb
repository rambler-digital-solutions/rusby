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
2.times do |i|
  puts "== #{i + 1} - #{pluser.plusplus(77)}"
end
