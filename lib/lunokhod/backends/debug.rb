module Lunokhod
  module Backends
    class Debug
      attr_accessor :level
      attr_reader :buffer

      def initialize
        @buffer = ""
      end

      def write
        puts buffer
      end

      def prologue
        buffer << "PROLOGUE\n"
      end

      def answer(n)
        if @in_grid
          @abuf << n
          yield
        else
          im n, "ANS #{tag(n)}: #{n.text} (#{n.uuid}, type: #{n.type})\n"
          im(n, "HELP TEXT: #{n.help_text}\n") if n.help_text
          yield
        end
      end

      def condition(n)
        im n, "COND #{tag(n)}: #{n.parsed_condition.inspect}\n"
        yield
      end

      def dependency(n)
        str = rule_to_sexp(n.parsed_rule)
        im n, "DEP #{str}\n"
        im n, "REFERENCED CONDS: #{n.referenced_conditions.inspect}\n"
        yield
      end

      def grid(n)
        im n, "GRID #{tag(n)} #{n.uuid} START\n"
        @in_grid = true
        @qbuf = []
        @abuf = []
        yield
        ms = @qbuf.map(&:text).map(&:length).max
        im n, (" " * ms) + @abuf.map(&:text).join("  ") + "\n"
        @qbuf.each { |q| im(q, "#{q.text}\n") }
        @in_grid = false
        im n, "GRID #{tag(n)} #{n.uuid} END\n"
      end

      def group(n)
        im n, "GROUP #{tag(n)}: #{n.uuid} START\n"
        im n, "#{n.name}\n"
        yield
        im n, "GROUP #{tag(n)}: #{n.uuid} END\n"
      end

      def label(n)
        im n, "LABEL #{n.text} (#{n.uuid})\n"
        im(n, "HELP TEXT: #{n.help_text}\n") if n.help_text
        yield
      end

      def question(n)
        if @in_grid
          @qbuf << n
          yield
        else
          im n, "QUESTION #{tag(n)}: #{n.uuid} START\n"
          im n, "#{n.text}\n"
          yield
          im n, "QUESTION #{tag(n)}: #{n.uuid} END\n"
        end
      end

      def repeater(n)
        im n, "REPEATER #{tag(n)}: #{n.uuid} START\n"
        yield
        im n, "REPEATER #{tag(n)}: #{n.uuid} END\n"
      end

      def section(n)
        im n, "SECTION #{tag(n)}: #{n.name} #{n.uuid} START\n"
        yield
        im n, "SECTION #{tag(n)}: #{n.name} #{n.uuid} END\n"
      end

      def survey(n)
        im n, "SURVEY #{n.uuid} START\n"
        im n, "SOURCE: #{n.source}\n"
        yield
        im n, "SURVEY #{n.uuid} END\n"
      end

      def translation(n)
        im n, "TRANSLATION #{n.lang} => #{n.path} (#{n.uuid})\n"
        yield
      end

      def validation(n)
        im n, "VDN #{n.uuid}\n"
        im n, n.parsed_rule.inspect + "\n"
        yield
      end

      def epilogue
        buffer << "EPILOGUE\n"
      end

      def im(n, msg)
        buffer << sprintf("%05d", n.line) << " " << ("  " * level) << msg
      end

      def tag(n)
        set_tag = n.tag.empty? ? '(no tag)' : n.tag

        if n.respond_to?(:surveyor_tag)
          "#{set_tag} (Surveyor tag interpretation: #{n.surveyor_tag.inspect})"
        else
          set_tag
        end
      end

      def rule_to_sexp(rule)
        if rule.respond_to?(:conj)
          "(#{rule.conj.op} #{rule_to_sexp(rule.left)} #{rule_to_sexp(rule.right)})"
        elsif rule.respond_to?(:name)
          rule.name
        end
      end
    end
  end
end
