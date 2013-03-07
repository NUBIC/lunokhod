require 'spec_helper'

module Cartographer
  describe ErrorReport do
    let(:ep) { ErrorReport.new(surveys) }
    let(:surveys) { p = Parser.new(data); p.parse; p.surveys }

    describe '#run' do
      let(:data) do
        %q{survey "foo" do
            section "bar" do
              q_1 "a question"
              a_1 "an answer"
              dependency :rule => "A or B"
              condition_A :q_oops, '==', :a_1
              q_1 "duplicate"
              a_1 "yep"
            end
          end

          survey "bar" do
            section "baz" do
              q_1 "a question"
              a_1 "an answer"
              dependency :rule => "A"
              condition_A :q_1, '==', :a_oops
            end
          end}
      end

      before do
        ep.run
      end

      def errors_for(sname)
        ep.errors.select { |e| e.survey.name == sname }
      end

      describe 'for each survey' do
        it 'finds unknown question references' do
          errors_for('foo').select(&:bad_question_tag?).length.should == 1
          errors_for('bar').select(&:bad_question_tag?).length.should == 0
        end

        it 'finds unknown answer references' do
          errors_for('foo').select(&:bad_answer_tag?).length.should == 1
          errors_for('bar').select(&:bad_answer_tag?).length.should == 1
        end

        it 'finds unknown condition references' do
          errors_for('foo').select(&:bad_condition?).length.should == 1
          errors_for('bar').select(&:bad_condition?).length.should == 0
        end

        it 'finds duplicate question references' do
          errors_for('foo').select(&:duplicate_question?).length.should == 1
          errors_for('bar').select(&:duplicate_question?).length.should == 0
        end
      end
    end
  end
end
