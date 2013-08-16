require 'spec_helper'

module Lunokhod
  describe Compiler do
    let(:test_backend) do
      Class.new do
        attr_accessor :nodes
        attr_accessor :level

        def initialize
          self.nodes = []
        end

        def prologue; end
        def epilogue; end

        def method_missing(m, *args)
          node = args.first
          nodes << node
          yield if block_given?
        end
      end
    end

    let(:backend) { test_backend.new }
    let(:node_class_sequence) { backend.nodes.map(&:class).uniq }

    def compile(data)
      p = Lunokhod::Parser.new(data, 'test')
      p.parse
      c = Lunokhod::Compiler.new(p.surveys, backend)
      c.compile
    end

    before do
      compile(data)
    end

    describe 'for groups' do
      let(:data) do
        %q{
          survey "foo" do
            section "bar" do
              group "one" do
                dependency :rule => "A"
                condition_A :q_a, '==', :a_1

                q_a "What"
                a_1 "No"
              end
            end
          end
        }
      end

      it "visits the group's dependencies before its questions" do
        node_class_sequence.should have_lcs([Ast::Group, Ast::Dependency, Ast::Question])
      end
    end

    describe 'for repeaters' do
      let(:data) do
        %q{
          survey "foo" do
            section "bar" do
              repeater "one" do
                dependency :rule => "A"
                condition_A :q_a, '==', :a_1

                q_a "What"
                a_1 "No"
              end
            end
          end
        }
      end

      it "visits the repeater's dependencies before its questions" do
        node_class_sequence.should have_lcs([Ast::Repeater, Ast::Dependency, Ast::Question])
      end
    end

    describe 'for grids' do
      let(:data) do
        %q{
          survey "foo" do
            section "bar" do
              grid "grid" do
                dependency :rule => "A"
                condition_A :q_a, '==', :a_1
                a_1 "No"
                q_b "What"
              end
            end
          end
        }
      end

      it "visits the grid's dependencies, answers, and questions in that order" do
        node_class_sequence.should have_lcs([Ast::Grid, Ast::Dependency, Ast::Answer, Ast::Question])
      end
    end
  end
end
