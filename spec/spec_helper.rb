ENV['FLUQ_ENV']  ||= "test"
ENV['FLUQ_ROOT'] ||= File.expand_path("../scenario/", __FILE__)

require 'bundler/setup'
require 'rspec'
require 'fluq/testing'
FluQ.logger = Logger.new(FluQ.root.join("log", "fluq.log").to_s)
require 'celluloid/rspec'

module FluQ::SpecHelpers

  def reactor
    @reactor ||= FluQ::Reactor.new
  end

end

RSpec.configure do |c|
  c.include FluQ::SpecHelpers
  c.before :suite do
    $LOAD_PATH.unshift FluQ.root.join('lib')
    Random.srand(1234)
  end
  c.after do
    FileUtils.rm_rf FluQ.root.join("tmp").to_s
  end
end
