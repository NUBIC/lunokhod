require 'lunokhod/verifier'
require 'stringio'

module Lunokhod
  class ErrorReport
    attr_reader :errors
    attr_reader :surveys

    def initialize(surveys)
      @errors = []
      @surveys = surveys
    end

    def errors?
      !errors.empty?
    end

    def run
      surveys.each do |s|
        v = Verifier.new(s)
        v.run { |error| errors << error }
      end
    end

    def to_s
      io = StringIO.new("")

      errors.each do |e|
        source = e.survey.source

        if e.bad_tag?
          io.puts "#{source}:#{e.at_fault.line}: #{e.node_type} #{e.key} is not defined"
        elsif e.duplicate_question?
          io.puts "#{source}: question tag #{e.key} is used multiple times"
          e.at_fault.each do |n|
            io.puts "  at #{file}:#{n.line}"
          end
        end
      end

      io.string
    end
  end
end
