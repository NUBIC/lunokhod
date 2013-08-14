require 'spec_helper'

describe Lunokhod::ConditionParsing do
  describe 'for inclusion conditions' do
    let(:survey) do
      %q{
        survey "foo" do
          section "bar" do
            q_abc "A question"
            a_qux "Yes"
            a_baz "No"

            label "Eh?"
            dependency :rule => "A or B"
            condition_A :abc, "==", :a_qux
            condition_B :q_abc, "==", :a_baz
          end
        end
      }
    end

    let(:parser) { Lunokhod::Parser.new(survey) }
    let(:label) { parser.surveys.first.sections.first.questions[1] }
    let(:condition_a) { label.dependencies.first.conditions[0] }
    let(:condition_b) { label.dependencies.first.conditions[1] }

    before do
      parser.parse
    end

    it 'returns the referenced question tag' do
      condition_a.qtag.should == 'abc'
    end

    it 'returns the original question reference' do
      condition_b.qref.should == :q_abc
    end
  end

  describe 'for conditions referencing answer values' do
    describe 'if an answer reference is not given' do
      let(:survey) do
        %Q{
          survey "foo" do
            section "bar" do
              q_abc "A question"
              answer_a :text

              q_def "Another question"
              dependency :rule => "A"
              condition_A :q_abc, "==", { :string_value => 'Qux' }
            end
          end
        }
      end

      let(:parser) { Lunokhod::Parser.new(survey) }

      it 'raises UnparseablePredicateError' do
        lambda { parser.parse }.should raise_error(Lunokhod::ConditionParsing::UnparseablePredicateError)
      end
    end
  end
end
