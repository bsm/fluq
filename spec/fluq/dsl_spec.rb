require 'spec_helper'

describe FluQ::DSL do

  let :subject do
    described_class.new reactor.current_actor, FluQ.root.join('../scenario/config/test.rb')
  end

  it 'should find & configure input' do
    subject.input(:socket) do
      bind 'tcp://localhost:76543'
    end
    subject.should have(1).inputs
    reactor.should have(:no).actors
  end

  it 'should find & configure handler' do
    subject.handler(:forward) do
      to 'tcp://localhost:87654'
    end
    subject.should have(1).handlers
    reactor.should have(:no).handlers
    reactor.should have(:no).actors
  end

  it 'should find namespaced handler' do
    subject.handler(:custom, :test_handler) do
      to 'tcp://localhost:87654'
    end
    subject.should have(1).handlers
    subject.handlers.last.first.should == FluQ::Handler::Custom::TestHandler
  end

  it 'should evaluate configuration' do
    subject.run
    reactor.should have(1).handlers
    reactor.should have(2).actors
  end

end
