$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

require 'pp'
require 'cartographer/backends/debug'
require 'cartographer/backends/webpage'
require 'cartographer/compiler'
require 'cartographer/parser'
require 'cartographer/verifier'

backend = Cartographer::Backends.const_get(ENV['BACKEND'] || 'Debug')
rev = `git rev-parse HEAD`.chomp
puts "Cartographer #{rev} - backend: #{backend}"

file = File.expand_path("../#{ARGV[0]}", __FILE__)
data = File.read(file)

p = Cartographer::Parser.new(data, file)
p.parse

v = Cartographer::Verifier.new(p.surveys)
ok = v.verify

b = backend.new
c = Cartographer::Compiler.new(p.surveys, b)

c.compile

b.write

puts '-' * 78

v.errors.each do |e|
  case e.error_type
  when :bad_ref then
    puts "#{file}:#{e.at_fault.line}: #{e.node_type} #{e.key} is not defined"
  when :duplicate_qref then
    puts "#{file}: question tag #{e.key} is used multiple times"
    e.at_fault.each do |n|
      puts "  at #{file}:#{n.line}"
    end
  end
end
