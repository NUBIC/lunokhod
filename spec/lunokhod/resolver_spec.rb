require 'spec_helper'

module Lunokhod
  describe Resolver do
    let(:resolver) { Resolver.new(surveys).tap { |r| r.run } }
    let(:surveys) { p = Parser.new(data); p.parse; p.surveys }

    let(:data) do
      %q{
        survey "foo" do
          section "one" do
            q_a "Some question"
            a_y "Yes"
            a_n "No"

            q_b "Another question"
            dependency :rule => "A"
            condition_A :q_a, "==", :a_y
          end
        end
      }
    end

    it 'resolves IDs of questions' do
      resolver.question_for('a').uuid.should_not be_nil
    end

    it 'resolves IDs of answers' do
      resolver.answer_for('a', 'n').uuid.should_not be_nil
    end
  end
end
