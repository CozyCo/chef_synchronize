# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chef_sync/version'

Gem::Specification.new do |spec|
  spec.name          = "chef_sync"
  spec.version       = ChefSync::VERSION
  spec.authors       = ["Rachel King"]
  spec.email         = ["rachel@cozy.co"]
  spec.summary       = %q{Sync a monolithic chef repo to a chef server.}
  spec.description   = %q{Sync a monolithic chef repo to a chef server.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"

  spec.add_runtime_dependency "chef"
  spec.add_runtime_dependency "ridley"
  spec.add_runtime_dependency "knife-api"
end
