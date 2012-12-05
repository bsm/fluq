ENV['FLUQ_ENV']  ||= "test"
ENV['FLUQ_ROOT'] ||= File.expand_path("../scenario/", __FILE__)

require 'bundler/setup'
require 'rspec'
require 'fluq'

Dir[Fluq.root.join("../support/**/*.rb")].each {|f| require f }
