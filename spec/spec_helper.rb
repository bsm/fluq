ENV['FLUQ_ENV']  ||= "test"
ENV['FLUQ_ROOT'] ||= File.expand_path("../scenario/", __FILE__)

require 'bundler/setup'
require 'rspec'
require 'fluq/testing'

FluQ.logger = Logger.new(FluQ.root.join("log", "fluq.log").to_s)
FluQ::Testing.track_exceptions!

$LOAD_PATH.unshift FluQ.root.join('lib')
Random.srand(1234)

module FluQ::SpecHelpers

  def self.included(base)
    super
    base.instance_eval do
      let(:reactor) { @_reactor ||= FluQ::Reactor.new }
    end
  end

  def with_reactor(&block)
    FluQ::Reactor.run do |reactor|
      @_reactor = reactor
      block.call(reactor)
      EM.stop
    end
  end

end

RSpec.configure do |c|
  c.include FluQ::SpecHelpers
  c.after do
    FileUtils.rm_rf FluQ.root.join("tmp").to_s
  end
end
