ENV['FLUQ_ENV']  ||= "test"
ENV['FLUQ_ROOT'] ||= File.expand_path("../scenario/", __FILE__)

require 'bundler/setup'
require 'rspec'
require 'coveralls'
Coveralls.wear!

require 'fluq/testing'
FluQ.logger = Logger.new(FluQ.root.join("log", "fluq.log").to_s)
require 'celluloid/rspec'

RSpec.configure do |c|
  c.before :suite do
    $LOAD_PATH.unshift FluQ.root.join('lib')
  end
  c.after do
    FileUtils.rm_rf FluQ.root.join("tmp").to_s
  end
end
