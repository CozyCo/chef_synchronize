# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chef_sync/version'

Gem::Specification.new do |spec|
  spec.name          = "chef-synchronize"
  spec.version       = ChefSync::VERSION
  spec.authors       = ["Rachel King"]
  spec.email         = ["opensource@cozy.co"]
  spec.summary       = %q{Sync a monolithic chef repo to a chef server.}
  spec.description   = %q{Sync a monolithic chef repo to a chef server.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = Dir[ '{lib,spec}/**/*.rb' ] +
                       Dir[ 'Rakefile', 'LICENSE.txt', 'README.md' ] +
                       Dir[ 'bin/*' ]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.4"

  spec.add_dependency "ridley", "~> 4.4"
  spec.add_dependency "knife-api", "~> 0.1"
  spec.add_dependency "slack-post", "~> 0.3"
  spec.add_dependency "tqdm", "~> 0.3"
  spec.add_dependency "mixlib-versioning", "~> 1.1"
end
