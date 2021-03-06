$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))

require 'lunokhod'

require File.expand_path('../matchers/have_lcs', __FILE__)
require File.expand_path('../support/node_extraction', __FILE__)

RSpec.configure do |c|
  c.include NodeExtraction
end
