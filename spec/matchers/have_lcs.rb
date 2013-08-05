require 'diff-lcs'

RSpec::Matchers.define :have_lcs do |expected|
  match do |actual|
    Diff::LCS.lcs(actual, expected).should == expected
  end

  failure_message_for_should do |actual|
    "expected subsequence #{expected.inspect} to be in #{actual.inspect}"
  end

  failure_message_for_should_not do |actual|
    "expected subsequence #{expected.inspect} to not be in #{actual.inspect}"
  end
end
