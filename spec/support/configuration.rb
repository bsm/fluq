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
end