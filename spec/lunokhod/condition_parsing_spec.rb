require 'spec_helper'

describe Lunokhod::ConditionParsing do
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
