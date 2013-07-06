require 'lunokhod/ast'
require 'lunokhod/visitation'

module Lunokhod
  ##
  # After a parse run, we have Condition nodes (among others).  These nodes
  # refer to Question and Answer nodes by their tag, but the references are not
  # resolved by the parser.  The reason is simple: the references might be
  # invalid, but they are still syntatically valid.
  #
  # This is where the Resolver steps in.
  #
  # The Resolver visits Condition, Question, and Answer nodes.  Dependencies
  # are cached for later resolution; tagged questions and answers are recorded.
  # Resolution results are recorded in the Resolver.
  class Resolver
    include Ast
    include Visitation

    def initialize(surveys)
      @surveys = surveys
      @mapping = {}
      @questions = {}
      @answers = {}
    end

    def run
      @surveys.each { |s| resolve(s) }
    end

    def question_for(qtag)
      @questions[qtag]
    end

    def answer_for(qtag, atag)
      @answers[[qtag, atag]]
    end
    
    private

    def resolve(survey)
      current_question = nil

      visit(survey, true) do |n, level, prev, _|
        case n
        when Question
          @questions[n.tag] = n
        when Answer
          @answers[[n.question.tag, n.tag]] = n
        end
      end
    end
  end
end
