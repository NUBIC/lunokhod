require 'spec_helper'
require 'lunokhod/backends/unparser'
require 'tempfile'

describe Lunokhod do
  describe "round-tripping Surveyor's kitchen sink survey through the Unparser" do
    let(:kitchen_sink_survey) {File.expand_path('../../../kitchen_sink_survey.rb', __FILE__)}
    let(:unparser) {Lunokhod::Backends::Unparser.new}

    def parse_resolve_check(data, name)
      p = Lunokhod::Parser.new(data, name);p.parse
      Lunokhod::Resolver.new(p.surveys).tap{|r|r.run}
      Lunokhod::ErrorReport.new(p.surveys).tap{|ep|ep.run; ep.errors?.should be_false}
      return p
    end

    def round_trip_kitchen_sink
      p1 = parse_resolve_check(File.read(kitchen_sink_survey), 'original')
      Lunokhod::Compiler.new(p1.surveys, unparser).compile
      p2 = parse_resolve_check(unparser.buffer, 'unparsed')
      [p1, p2]
    end

    it "generates identical survey text" do
      driver = File.expand_path('../../../bin/lunokhod-driver', __FILE__)
      dn = "/dev/null"

      Tempfile.open('out') do |f|
        Tempfile.open('out2') do |ff|
          system({'BACKEND' => 'Unparser'},
                 "#{driver} #{kitchen_sink_survey} > #{f.path} 2> #{dn};" +
                 "#{driver} #{f.path} > #{ff.path} 2> #{dn};"+
                 "diff #{f.path} #{ff.path}"
                 )
        end
      end
      $?.should be_success
    end

    it "generates identical ASTs" do
      p1, p2 = round_trip_kitchen_sink
      p2.surveys.should == p1.surveys
    end

    it "generates identical UUIDs" do
      p1, p2 = round_trip_kitchen_sink
      p2.surveys.map(&:uuid).should == p1.surveys.map(&:uuid)
    end
  end
end
