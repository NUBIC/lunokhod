$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

require 'pp'
require 'imperator/parser'
require 'imperator/compiler'
require 'imperator/backends/debug'
require 'imperator/backends/webpage'

backend = Imperator::Backends.const_get(ENV['BACKEND'] || 'Debug')
rev = `git rev-parse HEAD`.chomp
puts "Imperator #{rev} - backend: #{backend}"

file = ARGV[0]

p = Imperator::Parser.new(file)
p.parse

b = backend.new
c = Imperator::Compiler.new(p.surveys, b)

c.compile

b.write
