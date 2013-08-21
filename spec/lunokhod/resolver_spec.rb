require 'spec_helper'

module Lunokhod
  describe Resolver do
    include Visitation

    let(:resolver) { Resolver.new(surveys) }
    let(:surveys) { p = Parser.new(data); p.parse; p.surveys }
    let(:survey) { surveys.first }

    let(:data) do
      %q{
        survey "foo" do
          section "one" do
            q_a "Some question"
            a_y "Yes"
            a_n "No"
            a_other :string

            q_b "Another question", :pick => :any
            a "One"
            a "Two"
            dependency :rule => "A"
            condition_A :q_a, "==", :a_y

            q_c "Yet another question"
            dependency :rule => "A"
            condition_A :q_a, "==", { :string_value => "Foo", :answer_reference => "other" }

            q_d "More questions"
            dependency :rule => "A"
            condition_A :q_b, "count>1"
          end
        end
      }
    end

    def question_for(tag)
      visit(survey, true) { |n, _, _, _| break n if n.is_a?(Ast::Question) && n.tag == tag }
    end

    def answer_for(qtag, atag)
      visit(survey, true) do |n, _, _, _|
        if n.is_a?(Ast::Answer) && \
          n.tag == atag &&
          n.parent.tag == qtag
          break n
        end
      end
    end

    describe 'for AnswerSelected conditions' do
      before do
        resolver.run
      end

      it 'resolves question references' do
        condition_for(survey, 'b', 'A').referenced_question.should == question_for('a')
      end

      it 'resolves answer references' do
        condition_for(survey, 'b', 'A').referenced_answer.should == answer_for('a', 'y')
      end
    end

    describe 'for AnswerSatisfies conditions' do
      before do
        resolver.run
      end

      it 'resolves question references' do
        condition_for(survey, 'c', 'A').referenced_question.should == question_for('a')
      end

      it 'resolves answer references' do
        condition_for(survey, 'c', 'A').referenced_answer.should == answer_for('a', 'other')
      end
    end

    describe 'for AnswerCount conditions' do
      before do
        resolver.run
      end

      it 'resolves question references' do
        condition_for(survey, 'd', 'A').referenced_question.should == question_for('b')
      end
    end

    describe "if the condition's referenced question is already set" do
      before do
        condition_for(survey, 'b', 'A').referenced_question = :foo
      end

      it 'does not overwrite #referenced_question' do
        resolver.run

        condition_for(survey, 'b', 'A').referenced_question.should == :foo
      end
    end

    describe "if the condition's referenced answer is already set" do
      before do
        condition_for(survey, 'b', 'A').referenced_answer = :bar
      end

      it 'does not overwrite #referenced_answer' do
        resolver.run

        condition_for(survey, 'b', 'A').referenced_answer.should == :bar
      end
    end

    describe 'synonym definition' do
      let(:data) do
        %q{
          survey "foo" do
            section "one" do
              q_a "Some question"
              a_y "Yes"
              a_n "No"
              a_other :string

              q_b "Another question", :pick => :any
              a "One"
              a "Two"
              dependency :rule => "A or B"
              condition_A :question_a, "==", :answer_y
              condition_B :a, "!=", :n
            end
          end
        }
      end

      before do
        resolver.run
      end

      it 'treats question_foo as a synonym for q_foo' do
        condition_for(survey, 'b', 'A').referenced_question.should == question_for('a')
      end

      it 'treats answer_foo as a synonym for a_foo' do
        condition_for(survey, 'b', 'A').referenced_answer.should == answer_for('a', 'y')
      end

      it 'treats foo as a synonym for q_foo' do
        condition_for(survey, 'b', 'B').referenced_question.should == question_for('a')
      end

      it 'treats foo as a synonym for a_foo' do
        condition_for(survey, 'b', 'B').referenced_answer.should == answer_for('a', 'n')
      end
    end
  end
end
