# -*- encoding: utf-8 -*-
Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 1.9.1'
  s.required_rubygems_version = ">= 1.8.0"

  s.name        = File.basename(__FILE__, '.gemspec')
  s.summary     = "Fluq!"
  s.description = "The minimalistic stream processor"
  s.version     = "0.1.0"

  s.authors     = ["Black Square Media"]
  s.email       = "info@blacksquaremedia.com"
  s.homepage    = "https://github.com/bsm/fluq"

  s.require_path = 'lib'
  s.files        = Dir['lib/**/*']
  s.test_files   = Dir['spec/**/*']

  s.add_dependency "msgpack"
  s.add_dependency "celluloid-io"
  s.add_dependency "atomic"

  s.add_development_dependency "rake"
  s.add_development_dependency "bundler"
  s.add_development_dependency "rspec"
  s.add_development_dependency "yard"
end
