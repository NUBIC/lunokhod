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
  #
  # Theory of operation
  # -------------------
  #
  # The Resolver visits Condition, Question, and Answer nodes.  Conditions are
  # cached for later resolution; tagged questions and answers are recorded.
  # Once a survey is walked, Conditions are updated with the resolution
  # results.  The resolved nodes are available through the
  # #referenced_question and #referenced_answer accessors on Condition.
  class Resolver
    include Ast
    include Visitation

    def initialize(surveys)
      @surveys = surveys
    end

    def run
      @surveys.each { |s| resolve(s) }
    end
    
    private

    def resolve(survey)
      pending = []
      questions = {}
      answers = {}

      visit(survey, true) do |n, level, prev, _|
        case n
        when Question
          questions[n.tag] = n
        when Answer
          answers[[n.question.tag, n.tag]] = n
        when Condition
          pending << n
        end
      end

      pending.each do |n|
        if n.qtag
          n.referenced_question = questions[n.qtag]

          if n.atag
            n.referenced_answer = answers[[n.qtag, n.atag]]
          end
        end
      end
    end
  end
end
