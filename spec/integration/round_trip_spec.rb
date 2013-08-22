require 'spec_helper'
require 'lunokhod/backends/unparser'
require 'tempfile'

describe Lunokhod do
  context "round tripping Surveyor's kitchen sink survey" do
    let(:kitchen_sink_survey) {File.expand_path('../../../kitchen_sink_survey.rb', __FILE__)}
    def parse_resolve_check(data,name)
      p = Lunokhod::Parser.new(data, name);p.parse
      Lunokhod::Resolver.new(p.surveys).tap{|r|r.run}
      Lunokhod::ErrorReport.new(p.surveys).tap{|ep|ep.run; ep.errors?.should be_false}
      return p
    end

    it "the lunokhod-driver's output is identical" do
      driver = File.expand_path('../../../bin/lunokhod-driver', __FILE__)
      dn = "/dev/null"

      Tempfile.open ('out') do |f|
        Tempfile.open ('out2') do |ff|
          system({'BACKEND' => 'Unparser'},
                 "#{driver} #{kitchen_sink_survey} > #{f.path} 2> #{dn};" +
                 "#{driver} #{f.path} > #{ff.path} 2> #{dn};"+
                 "diff #{f.path} #{ff.path}"
                 )
        end
      end
      $?.should be_success
    end

    it "the ASTs are identical" do
      p1 = parse_resolve_check(File.read(kitchen_sink_survey),'original')
      Lunokhod::Compiler.new(p1.surveys, b=Lunokhod::Backends::Unparser.new).compile
      p2 = parse_resolve_check(b.buffer, 'unparsed')
      p2.surveys.should == p1.surveys
    end

    it "the UUIDs are identical" do
      p1 = parse_resolve_check(File.read(kitchen_sink_survey),'original')
      Lunokhod::Compiler.new(p1.surveys, b=Lunokhod::Backends::Unparser.new).compile
      p2 = parse_resolve_check(b.buffer, 'unparsed')
      p2.surveys.map(&:uuid).should == p1.surveys.map(&:uuid)
      p2.surveys.first.uuid.should == p1.surveys.first.uuid
    end
  end
end
