module Lunokhod
  module Backends
    class Unparser
      attr_accessor :level
      attr_reader :buffer

      def initialize
        @buffer = ""
      end

      def write
        puts buffer
      end

      def prologue
      end

      def epilogue
      end

      def survey(n)
        im "survey", r_args(n.name, n.options), 'do'
        yield
        im "end"
      end

      def translation(n)
        im "translations", r_args(n.lang => n.path)
        yield
      end

      def section(n)
        im "section#{tag(n)}", r_args(n.name, n.options), 'do'
        yield
        im "end"
      end

      def group(n)
        im "group#{tag(n)}", r_args(n.name, n.options), 'do'
        yield
        im "end"
      end

      def repeater(n)
        im "repeater#{tag(n)}", r_args(n.text), 'do'
        yield
        im "end"
      end

      def grid(n)
        im "grid#{tag(n)}", r_args(n.text), 'do'
        yield
        im "end"
      end

      def label(n)
        im "label#{tag(n)}", r_args(n.text, n.options)
        yield
      end

      def question(n)
        im "question#{tag(n)}", r_args(n.text, n.options)
        yield
      end

      def answer(n)
         im "answer#{tag(n)}", r_args(n.other ? :other : nil, n.text, n.type, n.options)
        yield
      end

      def dependency(n)
        im "dependency", r_args(:rule => n.rule)
        yield
      end

      def validation(n)
        im "validation", r_args(:rule => n.rule)
        yield
      end

      def condition(n)
        im "condition#{tag(n)}","#{condition_h(n)}"
        yield
      end

      def condition_h(n)
        case n.parsed_condition
        when Lunokhod::ConditionParsing::AnswerSelected
          r_args(n.qref, n.parsed_condition.op, n.aref)
        when Lunokhod::ConditionParsing::AnswerCount
          r_args(n.qref, 'count'+n.parsed_condition.op+n.parsed_condition.value.to_s)
        when Lunokhod::ConditionParsing::AnswerSatisfies
          r_args(n.qref, n.parsed_condition.op, n.parsed_condition.criterion => n.parsed_condition.value, :answer_reference => n.aref)
        when Lunokhod::ConditionParsing::SelfAnswerSatisfies
          r_args(n.parsed_condition.op, n.parsed_condition.criterion => n.parsed_condition.value)
        end
      end

      def im(*msgs)
        buffer << ("  " * level) << msgs.compact.join(' ') << "\n"
      end

      def tag(n)
        n.tag.empty? ? '' : "_#{n.tag}"
      end

      def r_hash_args(x)
        x=={} ? nil : x.inspect.sub(/^\{(.*)\}$/,'\1')
      end

      def r_args(*x)
        if x.last.is_a?(Hash)
          (x[0..-2].compact.map(&:inspect) << r_hash_args(x.last)).compact.join(', ')
        else
          x.compact.map(&:inspect).join(', ')
        end
      end
    end
  end
end
