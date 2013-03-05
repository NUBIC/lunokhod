# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cartographer/version'

Gem::Specification.new do |spec|
  spec.name          = "cartographer"
  spec.version       = Cartographer::VERSION
  spec.authors       = ["David Yip"]
  spec.email         = ["yipdw@northwestern.edu"]
  spec.description   = %q{Parsing and compilation tools for Surveyor surveys}
  spec.summary       = %q{Parsing and compilation tools for Surveyor surveys}
  spec.homepage      = "https://github.com/NUBIC/cartographer"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'case'
  spec.add_dependency 'uuidtools'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'kpeg'
  spec.add_development_dependency 'rspec'
end
