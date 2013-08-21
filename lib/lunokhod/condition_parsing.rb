module Lunokhod
  # Surveyor conditions are an odd language consisting of a mix of Ruby and
  # custom operators represented as strings.  The language's only documentation
  # is its implementation.
  #
  # This module is a katana built from a sledgehammer.  It's intended to be
  # mixed into Condition AST nodes.
  #
  # Synopsis
  # --------
  #
  #     cond.parse
  #     cond.parsed_condition => #<Selected question=:q_2, answer=:a_1>
  #
  #
  # The Surveyor condition language
  # -------------------------------
  #
  # We find the following forms in Surveyor's kitchen sink survey:
  #
  # 1. :q_2, "==", :a_1
  # 2. :q_2, "count>2"
  # 3. :q_montypython3, "==", {:string_value => "It is 'Arthur', King of the Britons", :answer_reference => "1"}
  # 4. :q_cooling_1, "!=", :a_4
  # 5. ">=", :integer_value => 0
  # 6. "=~", :regexp => "[0-9a-zA-z\. #]"
  #
  # These forms have the following (informal) meanings in English:
  #
  # 1. Answer 1 for question 2 is selected.
  # 2. Question 2 has more than two answers selected.
  # 3. Answer 1 for question montypython3 has string value "It is 'Arthur', King of the Britons".
  # 4. Answer a_4 for question cooling_1 is not selected.
  #
  # Forms 5 and 6 apply to validations (hence, answers), and are interpreted
  # as follows:
  #
  # 5. The answer's value, as an integer, is greater than or equal to zero.
  # 6. The answer's value, as a string, satisfies the regexp
  #    /[0-9a-zA-z\. #]/.
  #
  # These forms correspond to the following condition nodes:
  #
  # 1. AnswerSelected
  # 2. AnswerCount
  # 3. AnswerSatisfies
  # 4. AnswerSelected
  # 5. SelfAnswerSatisfies
  # 6. SelfAnswerSatisfies
  module ConditionParsing
    OP_REGEXP = />|>=|<|<=|==|=~|!=/

    module Normalization
      def qtag
        (qref =~ /q(?:uestion)?_(.*)/ ? $1 : qref).to_s
      end

      def atag
        (aref =~ /a(?:nswer)?_(.*)/ ? $1 : aref).to_s
      end
    end

    module Tests
      def qref?(v)
        v.is_a?(Symbol)
      end

      def op?(v)
        v =~ OP_REGEXP
      end

      def aref?(v)
        v.is_a?(Symbol)
      end

      def criterion(v)
        if v.is_a?(Hash) && (k = v.keys.detect { |k| k =~ /(?:_value|regexp)\Z/ })
          [k, v[k]]
        end
      end

      def criterion?(v)
        !criterion(v).nil?
      end
    end

    ##
    # An AnswerSelected condition is used for question dependencies.  It is
    # true if the selected answers for the given question are (or are not) a
    # subset of the question's possible answers.
    #
    # This condition refers to its question and answer by tag.
    class AnswerSelected < Struct.new(:qref, :op, :aref)
      extend Tests
      include Normalization

      def self.applies?(pred)
        qref?(pred[0]) &&
          (pred[1] == '==' || pred[1] == '!=') &&
          aref?(pred[2])
      end

      def self.build(pred, condition)
        new(pred[0], pred[1], pred[2])
      end
    end

    ##
    # An AnswerCount condition tests whether the number of answers for a given
    # question satisfies some threshold.
    #
    # This condition refers to its question by tag.
    class AnswerCount < Struct.new(:qref, :op, :value)
      extend Tests
      include Normalization

      COUNT = /count(#{OP_REGEXP})(\d+)/

      def self.applies?(pred)
        qref?(pred[0]) && pred[1] =~ COUNT
      end

      def self.build(pred, condition)
        pred[1] =~ COUNT

        new(pred[0], $1, $2.to_i)
      end

      def atag
        nil
      end
    end

    ##
    # An AnswerSatisfies condition tests whether the given answer on the given
    # question satisfies some value.
    #
    # The answer on the target question is specified using an :answer_reference
    # option.  If no reference is given, an error is raised.
    #
    # This condition refers to its question and answer by tag.
    class AnswerSatisfies < Struct.new(:qref, :op, :aref, :criterion, :value)
      extend Tests
      include Normalization

      def self.applies?(pred)
        qref?(pred[0]) && op?(pred[1]) && criterion?(pred[2]) && pred[2][:answer_reference]
      end

      def self.build(pred, condition)
        cri, value = criterion(pred[2])

        new(pred[0], pred[1], pred[2][:answer_reference], cri, value)
      end
    end

    ##
    # A SelfAnswerSatisfies condition tests whether its answer satisfies some
    # value.
    #
    # Unlike all other conditions, this one does not refer to its question and
    # answer by tag: the existence of both are implied by the survey's syntax.
    # However, qtag and atag readers are provided for interface consistency.
    class SelfAnswerSatisfies < Struct.new(:op, :criterion, :value, :q, :a)
      extend Tests

      def self.applies?(pred)
        op?(pred[0]) && criterion?(pred[1])
      end

      def self.build(pred, condition)
        op = pred[0]
        cri, value = criterion(pred[1])

        q = condition.question if condition.belongs_to_question?
        a = condition.answer if condition.belongs_to_answer?

        new(op, cri, value, q, a)
      end

      def qtag
        q.tag if q
      end

      def atag
        a.tag if a
      end
    end

    NODES = [
      AnswerSelected,
      AnswerCount,
      AnswerSatisfies,
      SelfAnswerSatisfies
    ]

    attr_reader :parsed_condition

    def parse_condition
      # Find out which nodes apply; only one should.  If we get multiple
      # matches, it's a fatal error.
      ns = applicable(predicate)
      raise "Ambiguous predicate: #{predicate}" if ns.length > 1
      raise UnparseablePredicateError, "Unparseable predicate: #{predicate}" if ns.length < 1

      # Parse it.
      @parsed_condition = ns.first.build(predicate, self)
    end

    def applicable(predicate)
      NODES.select { |n| n.applies?(predicate) }
    end

    class UnparseablePredicateError < StandardError
    end
  end
end
