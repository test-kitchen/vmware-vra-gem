# frozen_string_literal: true
lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "vra/version"

Gem::Specification.new do |spec|
  spec.name          = "vmware-vra"
  spec.version       = Vra::VERSION
  spec.authors       = ["Adam Leff", "JJ Asghar"]
  spec.email         = ["jj@chef.io"]
  spec.summary       = "Client gem for interacting with VMware vRealize Automation."
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/chef-partners/vmware-vra-gem"
  spec.license       = "Apache 2.0"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "ffi-yajl",       "~> 2.2"
  spec.add_dependency "passwordmasker", "~> 1.2"

  spec.add_development_dependency "bundler", ">= 1.7"
  spec.add_development_dependency "chefstyle"
  spec.add_development_dependency "pry",     "~> 0.10"
  spec.add_development_dependency "rake",    "~> 13.0"
  spec.add_development_dependency "rspec",   "~> 3.0"
  spec.add_development_dependency "webmock", "~> 3.5"

end
