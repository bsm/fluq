require 'spec_helper'

describe Fluq::Handler::Buffered do

  it { should be_a(Fluq::Handler::Base) }
  it { should respond_to(:on_flush) }
  its(:config) { should == { pattern: "*", flush_interval: 60, flush_rate: 0, buffer: "memory" } }
  its(:buffer) { should be_instance_of(Fluq::Buffer::Memory) }

  it 'should buffer events' do
    lambda {
      subject.on_event(Fluq::Event.new("tag", Time.now.to_i, {}))
    }.should change { subject.buffer.size }.by(1)
  end

end