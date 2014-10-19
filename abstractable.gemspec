# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "abstractable/version"

Gem::Specification.new do |spec|
  spec.name          = "abstractable"
  spec.version       = Abstractable::VERSION
  spec.authors       = ["Kenji Suzuki"]
  spec.email         = ["pujoheadsoft@gmail.com"]
  spec.summary       = "Library for define abstract method."
  spec.description   = "Library for define abstract method. Can know unimplemented abstract methods by fail fast as possible. This mechanism is very useful for prevent the implementation leakage."
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
