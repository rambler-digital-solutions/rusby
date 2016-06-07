require 'rubygems'
require 'bundler/setup'

require 'byebug'

Dir["./rusby/*.rb"].each {|file| require file }

class FanaticPluser
  extend Rusby::Core

  rust_method!
  def plusplus(number)
    number + 1
  end
end

pluser = FanaticPluser.new
2.times do |i|
  puts "== #{i + 1} - #{pluser.plusplus(77)}"
end
