require 'lunokhod/ast'
require 'case'

module Lunokhod
  class Parser < BasicObject
    attr_reader :data
    attr_reader :source
    attr_reader :surveys

    def initialize(data, source = '(input)')
      @data = data
      @source = source
      @surveys = []
      @qseq = 0
    end

    def parse
      instance_eval(data, source)
    end

    def survey(name, options = {}, &block)
      survey = build Ast::Survey, name, options
      survey.source = source
      @surveys << survey

      _with_unwind do
        @current_node = survey
        instance_eval(&block)
      end
    end

    def translations(spec)
      spec.each do |lang, path|
        translation = build Ast::Translation, lang, path
        translation.parent = @current_node
        @current_node.translations << translation
      end
    end

    def dependency(options = {})
      rule = options[:rule]
      dependency = build Ast::Dependency, rule

      # Does this apply to a question?  If not, we'll apply it to the current
      # node.
      if @current_question
        dependency.parent = @current_question
        @current_question.dependencies << dependency
      else
        dependency.parent = @current_node
        @current_node.dependencies << dependency
      end

      dependency.parse_rule
      @current_dependency = dependency
    end

    def validation(options = {})
      rule = options[:rule]
      validation = build Ast::Validation, rule
      validation.parent = @current_answer
      validation.parse_rule
      @current_answer.validations << validation
      @current_dependency = validation
    end

    def _grid(tag, text, &block)
      grid = build Ast::Grid, qseq, tag.to_s, text
      grid.parent = @current_node
      @current_node.questions << grid

      _with_unwind do
        @current_question = grid
        @current_node = grid
        instance_eval(&block)
      end
    end

    def _repeater(tag, text, &block)
      repeater = build Ast::Repeater, qseq, tag.to_s, text
      repeater.parent = @current_node
      @current_node.questions << repeater

      _with_unwind do
        @current_question = nil
        @current_node = repeater
        instance_eval(&block)
      end
    end

    def _label(tag, text, options = {})
      question = build Ast::Label, qseq, text, tag.to_s, options
      question.parent = @current_node
      @current_node.questions << question
      @current_question = question
    end

    def _question(tag, text, options = {})
      question = build Ast::Question, qseq, text, tag.to_s, options
      question.parent = @current_node
      @current_node.questions << question
      @current_question = question
    end

    def _answer(tag, t1, t2 = nil, options = {})
      text, type, other, options = _disambiguate_answer(t1, t2, options)
      answer = build Ast::Answer, text, type, other, tag.to_s, [], options

      answer.parent = @current_question
      @current_question.answers << answer
      @current_answer = answer
    end

    def _disambiguate_answer(t1, t2, options)
      c = ::Case

      case c[t1, t2]
      when c[::String, ::NilClass]
        [t1, nil, false, options]     # text, type, other, options
      when c[::String, ::Hash]
        [t1, nil, false, t2]
      when c[::String, ::Symbol]
        [t1, t2, false, options]
      when c[::Symbol, ::Hash]
        [nil, t1, false, t2]
      when c[::Symbol, ::NilClass]
        [nil, t1, false, options]
      when c[:other, ::Symbol]
        [nil, t2, true, options]
      else ::Kernel.raise "Unknown case #{[t1, t2].inspect}"
      end
    end

    def _condition(label, *predicate)
      condition = if @current_dependency.is_a?(Ast::Dependency)
                    build Ast::DependencyCondition, label, predicate
                  elsif @current_dependency.is_a?(Ast::Validation)
                    build Ast::ValidationCondition, label, predicate
                  else
                    ::Kernel.raise "Unknown parent node #{@current_dependency.inspect} for condition"
                  end

      condition.parent = @current_dependency
      condition.parse_condition
      @current_dependency.conditions << condition
    end

    def _group(tag, name = nil, options = {}, &block)
      group = build Ast::Group, tag.to_s, name, options
      group.parent = @current_node
      @current_node.questions << group

      _with_unwind do
        @current_question = nil
        @current_node = group
        instance_eval(&block)
      end
    end

    def _section(tag, name, options = {}, &block)
      section = build Ast::Section, tag.to_s, name, options
      section.parent = @current_node
      @current_node.sections << section

      _with_unwind do
        @current_node = section
        instance_eval(&block)
      end
    end

    def _with_unwind
      old_dependency = @current_dependency
      old_node = @current_node
      old_question = @current_question
      old_answer = @current_answer

      yield

      @current_dependency = old_dependency
      @current_node = old_node
      @current_question = old_question
      @current_answer = old_answer
    end

    # Current line in the survey.
    def sline
      ::Kernel.caller(1).detect { |l| l.include?(source) }.split(':')[1]
    end

    # Returns a fresh sequence number for questions and question-like entities.
    def qseq
      @qseq += 1
    end

    def build(node_class, *args)
      node_class.new(*args).tap { |n| n.line = sline }
    end

    # Intercept DSL keywords that may be suffixed with tags.
    def method_missing(m, *args, &block)
      case m
      when /^q(?:uestion)?(?:_(.+))?$/
        _question(*args.unshift($1), &block)
      when /^a(?:nswer)?(?:_(.+))?$/
        _answer(*args.unshift($1), &block)
      when /^l(?:abel)?(?:_(.+))?$/
        _label(*args.unshift($1), &block)
      when /^g(?:roup)?(?:_(.+))?$/
        _group(*args.unshift($1), &block)
      when /^s(?:ection)?(?:_(.+))?$/
        _section(*args.unshift($1), &block)
      when /^grid(?:_(.+))?$/
        _grid(*args.unshift($1), &block)
      when /^repeater(?:_(.+))?$/
        _repeater(*args.unshift($1), &block)
      when /^dependency_.+$/
        dependency(*args)
      when /^condition(?:_(.+))$/
        _condition(*args.unshift($1), &block)
      else
        super
      end
    end
  end
end
