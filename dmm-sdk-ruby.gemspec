# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dmm/sdk/ruby/version'

Gem::Specification.new do |spec|
  spec.name          = "dmm-sdk-ruby"
  spec.version       = Dmm::Sdk::Ruby::VERSION
  spec.authors       = ["sutoh"]
  spec.email         = ["sutoh.shohei@human-net.co.jp"]
  spec.description   = %q{ dmm-api はXML取得の為、Ruby用のsdk Library作成 }
  spec.summary       = %q{ sdk of dmm-api }
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
