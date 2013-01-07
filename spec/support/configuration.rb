require 'celluloid/rspec'

module FluQ::SpecHelpers

  def self.included(base)
    super
    base.instance_eval do
      let(:reactor) { FluQ::Reactor.new }
      after { Celluloid.shutdown }
    end
  end

  def with_reactor(&block)
    FluQ::Reactor.run do |reactor|
      block.call(reactor)
      EM.stop
    end
  end

end

RSpec.configure do |c|
  c.include FluQ::SpecHelpers
end