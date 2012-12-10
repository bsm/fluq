ENV['FLUQ_ENV']  ||= "test"
ENV['FLUQ_ROOT'] ||= File.expand_path("../scenario/", __FILE__)

require 'bundler/setup'
require 'rspec'
require 'fluq'

Dir[FluQ.root.join("../support/**/*.rb")].each {|f| require f }
Celluloid.logger = Logger.new(FluQ.root.join("log", "fluq.log").to_s)
