$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

require 'pp'
require 'lunokhod/backends/debug'
require 'lunokhod/backends/webpage'
require 'lunokhod'

backend = Lunokhod::Backends.const_get(ENV['BACKEND'] || 'Debug')
rev = `git rev-parse HEAD`.chomp
puts "Lunokhod #{rev} - backend: #{backend}"

file = File.expand_path("../#{ARGV[0]}", __FILE__)
data = File.read(file)

p = Lunokhod::Parser.new(data, file)
p.parse

ep = Lunokhod::ErrorReport.new(p.surveys)
ep.run

b = backend.new
c = Lunokhod::Compiler.new(p.surveys, b)

c.compile

b.write

puts '-' * 78
puts ep if ep.errors?
