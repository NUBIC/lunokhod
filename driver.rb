$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

require 'pp'
require 'cartographer/backends/debug'
require 'cartographer/backends/webpage'
require 'cartographer'

backend = Cartographer::Backends.const_get(ENV['BACKEND'] || 'Debug')
rev = `git rev-parse HEAD`.chomp
puts "Cartographer #{rev} - backend: #{backend}"

file = File.expand_path("../#{ARGV[0]}", __FILE__)
data = File.read(file)

p = Cartographer::Parser.new(data, file)
p.parse

ep = Cartographer::ErrorReport.new(p.surveys)
ep.run

b = backend.new
c = Cartographer::Compiler.new(p.surveys, b)

c.compile

b.write

puts '-' * 78
puts ep if ep.errors?
