require 'rubygems'
require 'bundler/setup'

Bundler.require
Dir['./rusby/*.rb'].each { |file| require file }
Dir['./examples/*.rb'].each { |file| require file }

pluser = FanaticPluser.new
2.times do |i|
  puts "== #{i + 1} - #{pluser.plusplus(77)}"
end
