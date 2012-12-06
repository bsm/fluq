require 'spec_helper'

describe Fluq::DSL do
  let :subject do
    described_class.new Fluq.root.join('../scenario/config.rb')
  end

  it 'should find & configure input' do
    subject.input(:socket) do
      bind 'tcp://localhost:76543'
    end
    subject.inputs.last.should be_a(Fluq::Input::Socket)
    subject.inputs.last.url.to_s.should == 'tcp://localhost:76543'
  end

  it 'should find & configure handler' do
    subject.handler(:forward) do
      to 'tcp://localhost:87654'
    end
    subject.handlers.last.should be_a(Fluq::Handler::Forward)
    subject.handlers.last.urls.should have(1).item
    subject.handlers.last.urls.first.to_s.should == 'tcp://localhost:87654'
  end

  it 'should evaluate configuration' do
    runner = Thread.new { subject.run }; sleep 0.01
    subject.inputs.should have(1).item
    subject.handlers.should have(1).item
    Fluq.reactor.handlers.should have(1).item
  end

end
