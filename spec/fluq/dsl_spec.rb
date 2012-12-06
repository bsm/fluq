require 'spec_helper'

describe Fluq::DSL do
  let :subject do
    described_class.new Fluq.root.join('../scenario/config.rb')
  end

  it 'should find & configure input' do
    subject.input(:socket) do
      bind 'tcp://localhost:7654'
    end
    subject.inputs.last.should be_a(Fluq::Input::Socket)
    subject.inputs.last.url.to_s.should == 'tcp://localhost:7654'
  end

  it 'should find & configure handler' do
    subject.handler(:forward) do
      urls 'tcp://localhost:7654'
    end
    subject.handlers.last.should be_a(Fluq::Handler::Forward)
    subject.handlers.last.urls.should have(1).item
    subject.handlers.last.urls.first.to_s.should == 'tcp://localhost:7654'
  end

  it 'should evaluate configuration' do
    subject.run
    subject.hould have(1).input
    subject.hould have(1).handler
  end


end
