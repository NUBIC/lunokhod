require 'spec_helper'

module Cartographer
  describe Parser do
    let(:parser) { Parser.new(data, 'fake') }
    let(:ast) { parser.surveys.first }

    describe 'for answers' do
      let(:data) do
        %q{
          survey "fake" do
            section "one" do
              q_a "A question"
              a "An answer", :string
              a "An answer with options", :help_text => "Yep"
              a "An answer with everything", :string, :help_text => "Yep"
              a :string
              a :other, :string
            end
          end
        }
      end

      before do
        parser.parse
      end

      let(:answers) { ast.sections[0].questions[0].answers }

      it 'parses answer response class' do
        answers[0].type.should == :string
        answers[0].options.should be_empty
      end

      it 'parses options on answers' do
        answers[1].options.should == { :help_text => 'Yep' }
      end

      it 'parses answers with options and response class' do
        answers[2].type.should == :string
        answers[2].options.should == { :help_text => 'Yep' }
      end

      it 'parses answers with a response class but no text' do
        answers[3].type.should == :string
        answers[3].options.should be_empty
      end

      it 'parses the "other" answer type with a response class' do
        answers[4].should be_other
        answers[4].type.should == :string
        answers[4].options.should be_empty
      end
    end
  end
end
