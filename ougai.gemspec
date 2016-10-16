# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ougai/version'

Gem::Specification.new do |spec|
  spec.name          = "ougai"
  spec.version       = Ougai::VERSION
  spec.authors       = ["Toshimitsu Takahashi"]
  spec.email         = ["toshi@tilfin.com"]

  spec.summary       = %q{JSON logger compatible node-bunyan.}
  spec.description   = %q{JSON logger compatible bunyan for Node.js}
  spec.homepage      = "https://github.com/tilfin/ougai"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.require_paths = ['lib']

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
