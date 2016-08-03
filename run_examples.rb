require 'rubygems'
require 'bundler/setup'

Bundler.require
Dir['./rusby/**/*.rb'].each { |file| require file }
Dir['./examples/*.rb'].each { |file| require file }

# pluser = FanaticPluser.new
# 2.times do |i|
#   puts "== #{i + 1} - #{pluser.plusplus(77)}"
# end
#
# sorter = Quicksort.new
# a = (1..50).map { |_i| rand(100_000) }
# 2.times do |i|
#   puts "=> #{i + 1} time method is being called".colorize(:light_black)
#   puts "== #{i + 1} - #{sorter.quicksort(a.clone, 0, a.size - 1)}"
# end
#
# greeter = FanaticGreeter.new
# 2.times do |_i|
#   puts greeter.greet('Fred')
# end
#
# measurer = Levenshtein.new
# params = %w(unimaginatively incomprehensibilities)
# 2.times do |i|
#   puts "#{i + 1}: #{measurer.distance(*params)}"
# end

randomizer = WeightedRandom.new
weights = (1..100000).map { rand(1000).to_f }
2.times do |i|
  puts "#{i + 1}: #{randomizer.pick(weights, rand())}"
end
