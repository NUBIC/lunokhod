require 'lunokhod/condition_parsing'
require 'lunokhod/rule_parsing'
require 'forwardable'
require 'uuidtools'

module Lunokhod
  module Ast
    LUNOKHOD_V0_NAMESPACE = UUIDTools::UUID.parse('ecab6cb2-8755-11e2-8caf-b8f6b111aef5')

    # Every AST node has an identity and a source line number.
    #
    # Nodes are content-addressable
    # -----------------------------
    #
    # A node's identity is a v5 UUID based on the Lunokhod namespace (see
    # LUNOKHOD_V0_NAMESPACE), the node's attributes (i.e. struct members).
    #
    # Changes to a node's children propagate up all the way to the root.
    # Therefore, survey equality can be checked by only comparing the UUIDs of
    # two survey nodes.
    #
    #
    # On line number tracking
    # -----------------------
    #
    # Line number tracking is useful, but we don't want it to be part of a
    # node's identity.
    #
    # Why?
    #
    # Because these two surveys have identical content:
    #
    # 1   survey "foo" do           survey "foo" do
    # 2     section "bar" do
    # 3     end                       section "bar" do
    # 4   end                         end
    # 5                             end
    module AstNode
      attr_accessor :line

      def identity
        @identity ||= ident(self)
      end

      def ident(o)
        case o
        when NilClass, TrueClass, FalseClass, Numeric, Symbol, String then o.class.name + o.to_s
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

    module SurveyorTag
      ##
      # Surveyor interprets tags from two places:
      #
      # 1. the method tag
      # 2. the :reference_identifier option
      #
      # This override is not intentional; it's just that the method's tag and
      # the :reference_identifier option end up in the same column in
      # Surveyor's database.
      #
      # There is no documented precedence rule, but analysis of Surveyor code
      # and experiments have shown me that #2 usually overrides #1.
      def surveyor_tag
        options[:reference_identifier] || tag
      end
    end

    class Survey < Struct.new(:name, :options, :sections, :translations)
      include AstNode
      include CommonOptions

      attr_accessor :parent
      attr_accessor :source

      def initialize(*)
        super

        self.sections ||= []
        self.translations ||= []
      end

      def children
        translations + sections
      end
    end

    class Translation < Struct.new(:lang, :path)
      include AstNode

      attr_accessor :parent

      def children
        []
      end
    end

    class Section < Struct.new(:tag, :name, :options, :questions)
      include AstNode
      include CommonOptions
      include SurveyorTag

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

    class Label < Struct.new(:seq, :text, :tag, :options, :dependencies)
      include AstNode
      include CommonOptions
      include SurveyorTag

      attr_accessor :parent

      def initialize(*)
        super

        self.dependencies ||= []
      end

      def children
        dependencies
      end
    end

    class Question < Struct.new(:seq, :text, :tag, :options, :answers, :dependencies)
      include AstNode
      include CommonOptions
      include SurveyorTag

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

    class Answer < Struct.new(:text, :type, :other, :tag, :validations, :options)
      include AstNode
      include CommonOptions
      include SurveyorTag

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

      def question
        parent
      end
    end

    class Dependency < Struct.new(:rule, :conditions)
      include AstNode
      include RuleParsing

      attr_accessor :parent

      def initialize(*)
        super

        self.conditions ||= []
      end

      def question
        parent
      end

      def children
        conditions
      end
    end

    class Validation < Struct.new(:rule, :conditions)
      include AstNode
      include RuleParsing

      attr_accessor :parent

      def initialize(*)
        super

        self.conditions ||= []
      end

      def answer
        parent
      end

      def children
        conditions
      end
    end

    class Group < Struct.new(:tag, :name, :options, :questions, :dependencies)
      include AstNode
      include CommonOptions
      include SurveyorTag

      attr_accessor :parent

      def initialize(*)
        super

        self.questions ||= []
        self.dependencies ||= []
      end

      def children
        dependencies + questions
      end
    end

    class Condition < Struct.new(:tag, :predicate)
      extend Forwardable
      include AstNode
      include ConditionParsing

      attr_accessor :parent
      attr_accessor :referenced_question, :referenced_answer

      def_delegators :parsed_condition, :qtag, :atag, :qref, :aref

      def children
        []
      end
    end

    class DependencyCondition < Condition
      def question
        parent.question
      end

      def belongs_to_question?
        true
      end

      def belongs_to_answer?
        false
      end
    end

    class ValidationCondition < Condition
      def answer
        parent.answer
      end

      def belongs_to_question?
        false
      end

      def belongs_to_answer?
        true
      end
    end

    class Grid < Struct.new(:seq, :tag, :text, :questions, :answers, :dependencies)
      include AstNode

      attr_accessor :parent

      def initialize(*)
        super

        self.answers ||= []
        self.questions ||= []
        self.dependencies ||= []
      end

      def children
        dependencies + questions + answers
      end
    end

    class Repeater < Struct.new(:seq, :tag, :text, :questions, :dependencies)
      include AstNode

      attr_accessor :parent

      def initialize(*)
        super

        self.questions ||= []
        self.dependencies ||= []
      end

      def children
        dependencies + questions
      end
    end
  end
end
