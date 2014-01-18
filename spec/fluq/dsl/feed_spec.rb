require 'spec_helper'

describe FluQ::DSL::Feed do

  let(:root) { FluQ::DSL::Root.new FluQ.root.join('../scenario/config/test.rb') }
  subject    { root.feeds.first }

  it  { should be_instance_of(described_class) }
  it  { should have(1).inputs }
  it  { should have(1).handlers }

  it 'should find & configure input' do
    subject.input(:socket) do
      bind 'tcp://localhost:76543'
    end
    subject.should have(2).inputs
    subject.inputs.last.should == [FluQ::Input::Socket, {bind: "tcp://localhost:76543"}]
  end

  it 'should find & configure handler' do
    subject.handler(:log)
    subject.should have(2).handlers
  end

  it 'should find namespaced handler' do
    subject.handler(:custom, :test_handler) do
      to 'tcp://localhost:87654'
    end
    subject.should have(2).handlers
    subject.handlers.last.should == [FluQ::Handler::Custom::TestHandler, {to: "tcp://localhost:87654"}]
  end

end
