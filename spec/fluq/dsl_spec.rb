require 'spec_helper'

describe Fluq::DSL do

  let :subject do
    described_class.new Fluq.root.join('../scenario/config.rb')
  end

  it 'should find & configure input' do
    subject.input(:socket) do
      bind 'tcp://localhost:76543'
    end
    subject.should have(1).inputs
    Fluq.reactor.inputs.should have(:no).actors
  end

  it 'should find & configure handler' do
    subject.handler(:forward) do
      to 'tcp://localhost:87654'
    end
    subject.should have(1).handlers
    Fluq.reactor.should have(:no).handlers
  end

  it 'should evaluate configuration' do
    runner = Thread.new { subject.run }; sleep 0.01
    Fluq.reactor.inputs.should have(1).actors
    Fluq.reactor.should have(1).handlers
  end
end
