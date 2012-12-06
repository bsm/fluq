require 'spec_helper'

describe FluQ::DSL do

  let :subject do
    described_class.new FluQ.root.join('../scenario/config.rb')
  end

  it 'should find & configure input' do
    subject.input(:socket) do
      bind 'tcp://localhost:76543'
    end
    subject.should have(1).inputs
    FluQ.reactor.inputs.should have(:no).actors
  end

  it 'should find & configure handler' do
    subject.handler(:forward) do
      to 'tcp://localhost:87654'
    end
    subject.should have(1).handlers
    FluQ.reactor.should have(:no).handlers
  end

  it 'should evaluate configuration' do
    runner = Thread.new { subject.run }; sleep 0.01
    FluQ.reactor.inputs.should have(1).actors
    FluQ.reactor.should have(1).handlers
  end
end
