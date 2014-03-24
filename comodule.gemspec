# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'comodule/version'

Gem::Specification.new do |spec|
  spec.name          = "comodule"
  spec.version       = Comodule::VERSION
  spec.authors       = ["Goto Kei"]
  spec.email         = ["kgoto@zeneffect.co.jp"]
  spec.summary       = %q{The useful library for Rails}
  spec.description   = %q{The useful library for Rails}
  spec.homepage      = "https://github.com/zeneffect/comodule"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
