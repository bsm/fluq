# -*- encoding: utf-8 -*-

$:.push File.expand_path("../lib", __FILE__)
require "fluq/version"

Gem::Specification.new do |s|
  s.platform = "jruby"
  s.required_ruby_version = '>= 1.9.1'
  s.required_rubygems_version = ">= 1.8.0"

  s.name        = File.basename(__FILE__, '.gemspec')
  s.summary     = "FluQ"
  s.description = "The minimalistic stream processor"
  s.version     = FluQ::VERSION.dup

  s.authors     = ["Black Square Media"]
  s.email       = "info@blacksquaremedia.com"
  s.homepage    = "https://github.com/bsm/fluq"

  s.require_path = 'lib'
  s.files        = Dir['lib/**/*']
  s.test_files   = Dir['spec/**/*']

  s.add_dependency "msgpack-jruby"
  s.add_dependency "celluloid-io"
  s.add_dependency "atomic"
  s.add_dependency "multi_json"

  s.add_development_dependency "rake"
  s.add_development_dependency "bundler"
  s.add_development_dependency "rspec"
  s.add_development_dependency "yard"
end
