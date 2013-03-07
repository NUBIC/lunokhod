require 'lunokhod/condition_parsing'
require 'lunokhod/rule_parsing'
require 'uuidtools'

module Lunokhod
  module Ast
    LUNOKHOD_V0_NAMESPACE = UUIDTools::UUID.parse('ecab6cb2-8755-11e2-8caf-b8f6b111aef5')

    module Identifiable
      def identity
        @identity ||= ident(self)
      end

      def ident(o)
        case o
        when NilClass, TrueClass, FalseClass, Numeric, Symbol, String then o.to_s
        when Hash then o.keys.sort.map { |k| ident([k, o[k]]) }.flatten.join
        when Array then o.map { |v| ident(v) }.flatten.join
        when Struct then o.values.map { |v| ident(v) }.flatten.join
        else raise "Cannot derive identity of #{o.class}"
        end
      end

      def uuid
        UUIDTools::UUID.sha1_create(LUNOKHOD_V0_NAMESPACE, identity)
      end
    end

    module CommonOptions
      %w(help_text custom_class display_type pick).each do |m|
        class_eval <<-END
          def #{m}
            options[:#{m}]
          end
        END
      end
    end

    class Survey < Struct.new(:line, :name, :options, :sections, :translations, :source)
      include CommonOptions
      include Identifiable

      attr_accessor :parent

      def initialize(*)
        super

        self.sections ||= []
        self.translations ||= []
      end

      def children
        translations + sections
      end
    end

    class Translation < Struct.new(:line, :lang, :path)
      include Identifiable

      attr_accessor :parent

      def children
        []
      end
    end

    class Section < Struct.new(:line, :tag, :name, :options, :questions)
      include CommonOptions
      include Identifiable

      attr_accessor :parent

      alias_method :survey, :parent

      def initialize(*)
        super

        self.questions ||= []
      end

      def children
        questions
      end
    end

    class Label < Struct.new(:line, :text, :tag, :options, :dependencies)
      include CommonOptions
      include Identifiable

      attr_accessor :parent

      def initialize(*)
        super

        self.dependencies ||= []
      end

      def children
        dependencies
      end
    end

    class Question < Struct.new(:line, :text, :tag, :options, :answers, :dependencies)
      include CommonOptions
      include Identifiable

      attr_accessor :parent

      def initialize(*)
        super

        self.answers ||= []
        self.dependencies ||= []
      end

      def children
        answers + dependencies
      end
    end

    class Answer < Struct.new(:line, :text, :type, :other, :tag, :validations, :options)
      include CommonOptions
      include Identifiable

      attr_accessor :parent

      def initialize(*)
        super

        self.validations ||= []
        self.other ||= false
      end

      def children
        validations
      end

      def other?
        other
      end
    end

    class Dependency < Struct.new(:line, :rule, :conditions)
      include Identifiable
      include RuleParsing

      attr_accessor :parent

      def initialize(*)
        super

        self.conditions ||= []
      end

      def children
        conditions
      end
    end

    class Validation < Struct.new(:line, :rule, :conditions)
      include Identifiable
      include RuleParsing

      attr_accessor :parent

      def initialize(*)
        super

        self.conditions ||= []
      end

      def children
        conditions
      end
    end

    class Group < Struct.new(:line, :tag, :name, :options, :questions, :dependencies)
      include CommonOptions
      include Identifiable

      attr_accessor :parent

      def initialize(*)
        super

        self.questions ||= []
        self.dependencies ||= []
      end

      def children
        questions + dependencies
      end
    end

    class Condition < Struct.new(:line, :tag, :predicate)
      include Identifiable
      include ConditionParsing

      attr_accessor :parent

      def children
        []
      end
    end

    class Grid < Struct.new(:line, :tag, :text, :questions, :answers)
      include Identifiable

      attr_accessor :parent

      def initialize(*)
        super

        self.answers ||= []
        self.questions ||= []
      end

      def children
        questions + answers
      end
    end

    class Repeater < Struct.new(:line, :tag, :text, :questions, :dependencies)
      include Identifiable

      attr_accessor :parent

      def initialize(*)
        super

        self.questions ||= []
        self.dependencies ||= []
      end

      def children
        questions + dependencies
      end
    end
  end
end
