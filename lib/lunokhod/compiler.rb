require 'fiber'
require 'lunokhod/ast'
require 'lunokhod/visitation'

module Lunokhod
  class Compiler
    include Ast
    include Visitation

    attr_reader :backend
    attr_reader :surveys

    def initialize(surveys, backend)
      @backend = backend
      @surveys = surveys
    end

    def compile
      backend.prologue

      stack = []

      surveys.each do |s|
        visit(s) do |n, level, prev, boundary|
          m = backend_method_for(n)
          backend.level = level

          if boundary == :enter
            co = Fiber.new do
              backend.send(m, n) do
                stack << Fiber.current
                Fiber.yield
              end
            end

            co.resume
          elsif boundary == :exit
            stack.pop.resume
          end
        end
      end

      backend.epilogue
    end

    def backend_method_for(n)
      case n
      when Answer; :answer
      when Condition; :condition
      when Dependency; :dependency
      when Grid; :grid
      when Group; :group
      when Label; :label
      when Question; :question
      when Repeater; :repeater
      when Section; :section
      when Survey; :survey
      when Translation; :translation
      when Validation; :validation
      else raise "Unhandled node type #{n.class}"
      end
    end
  end
end
