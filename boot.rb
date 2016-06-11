require 'rubygems'
require 'bundler/setup'

Bundler.require
Dir['./rusby/*.rb'].each { |file| require file }
Dir['./examples/*.rb'].each { |file| require file }

# pluser = FanaticPluser.new
# 2.times do |i|
#   puts "== #{i + 1} - #{pluser.plusplus(77)}"
# end

sorter = Quicksort.new
a = (1..5).map { |i| rand(10)  }

1.times do |i|
  puts "== #{i + 1} - #{sorter.quicksort(a.clone, 0, a.size - 1)}"
end
