require 'erb'

module Cartographer
  module Backends
    class Webpage
      attr_accessor :compiler
      attr_reader :buffer

      attr_reader :survey_title
      attr_reader :survey_js
      attr_reader :survey_html
      attr_reader :elapsed

      alias_method :h, :survey_html
      alias_method :j, :survey_js

      def initialize
        @survey_js = ""
        @survey_html = ""
      end

      def write
        template = ERB.new(asset('page.html.erb'))
        puts template.result(binding)
      end

      def prologue
      end

      def epilogue
      end

      def answer(n, &block)
        case @qtype
        when :radio then pick_answer('radio', n, block)
        when :checkbox then pick_answer('checkbox', n, block)
        else yield
        end
      end

      def pick_answer(type, n, block)
        name = n.parent.uuid

        h << %Q{
          <li>
        }

        if n.type == :other
          h << %Q{
            <label for="#{n.uuid}">Other</label>
            <input type="text" name="#{name}" id="#{n.uuid}" data-uuid="#{n.uuid}" data-tag="#{n.tag}" class="cartographer-answer cartographer-answer-pick-one cartographer-answer-other">
          }

          j << %Q{
            $(function() {
                $("##{n.uuid}").focus(function() {
                  $('input[name="#{name}"]').prop('checked', '');
                });
            });
          }
        elsif n.type == :omit
          h << %Q{
            <input type="#{type}" name="#{name}" id="#{n.uuid}" data-uuid="#{n.uuid}" data-tag="#{n.tag}" value="#{n.uuid}" class="cartographer-answer cartographer-answer-pick-one cartographer-answer-omit">
            <label for="#{n.uuid}">Omit</label>
          }

          j << %Q{
            $(function() {
                $("##{n.uuid}").change(function() {
                  var sel = $(this).prop('checked');

                  $('input[name="#{name}"]').prop('checked', !sel).prop('enabled', !sel)
                });
            });
          }
        else
          h << %Q{
            <input type="#{type}" name="#{name}" id="#{n.uuid}" data-uuid="#{n.uuid}" data-tag="#{n.tag}" value="#{n.uuid}" class="cartographer-answer cartographer-answer-pick-one">
            <label for="#{n.uuid}">#{n.text}</label>
          }
        end

        block.call

        h << %Q{
            </input>
          </li>
        }
      end

      def condition(n)
        yield
      end

      def dependency(n)
        yield
      end

      def grid(n)
        yield
      end

      def group(n)
        yield
      end

      def label(n)
        yield
      end

      def question(n)
        h << %Q{
          <li data-uuid="#{n.uuid}" data-tag="#{n.tag}" class="cartographer-question">
            #{n.text}
            <ol class="cartographer-answers">
        }

        pick = n.options[:pick]

        @qtype = case pick
                 when :one then :radio
                 when :any then :checkbox
                 end

        yield

        h << %Q{
            </ol>
          </li>
        }
      end

      def repeater(n)
        yield
      end

      def section(n)
        h << %Q{
          <section data-uuid="#{n.uuid}" data-tag="#{n.tag}" class="cartographer-section">
            <header>
              <h1>#{n.name}</h1>
            </header>
            <ol class="cartographer-questions">
        }

        yield

        h << %Q{
            </ol>
          </section>
        }
      end

      def survey(n)
        start = Time.now

        h << %Q{
          <article data-uuid="#{n.uuid}" class="cartographer-survey">
            <header>
              <h1>#{n.name}</h1>
            </header>
        }

        yield

        h << %Q{
          </article>
        }

        done = Time.now
        @elapsed = done - start
      end

      def translation(n)
        yield
      end

      def validation(n)
        yield
      end

      def asset(path)
        File.read(asset_path(path))
      end

      def asset_path(path)
        File.expand_path("../webpage/#{path}", __FILE__)
      end
    end
  end
end
