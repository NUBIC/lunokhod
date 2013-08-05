require 'spec_helper'

describe Lunokhod do
  it "can compile Surveyor's kitchen sink survey" do
    driver = File.expand_path('../../../bin/lunokhod-driver', __FILE__)
    survey = File.expand_path('../../../kitchen_sink_survey.rb', __FILE__)

    system("#{driver} #{survey} > /dev/null 2>&1")

    $?.should be_success
  end
end
