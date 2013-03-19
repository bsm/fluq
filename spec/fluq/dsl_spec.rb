require 'spec_helper'

describe FluQ::DSL do

  def dsl(reactor)
    described_class.new reactor, FluQ.root.join('../scenario/config/test.rb')
  end

  subject do
    dsl(reactor)
  end

  it 'should find & configure input' do
    subject.input(:socket) do
      bind 'tcp://localhost:76543'
    end
    subject.should have(1).inputs
    reactor.should have(:no).inputs
  end

  it 'should find & configure handler' do
    subject.handler(:log)
    subject.should have(1).handlers
    reactor.should have(:no).handlers
  end

  it 'should find namespaced handler' do
    subject.handler(:custom, :test_handler) do
      to 'tcp://localhost:87654'
    end
    subject.should have(1).handlers
    subject.handlers.last.first.should == FluQ::Handler::Custom::TestHandler
  end

  it 'should evaluate configuration' do
    with_reactor do |reactor|
      dsl(reactor).run
      reactor.should have(1).handlers
      reactor.should have(1).inputs
    end
  end

end
