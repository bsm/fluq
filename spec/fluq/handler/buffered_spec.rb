require 'spec_helper'

describe FluQ::Handler::Buffered do

  subject { described_class.new reactor }

  it { should be_a(FluQ::Handler::Base) }
  it { should respond_to(:on_flush) }
  its(:config) { should == { pattern: "*", flush_interval: 60, flush_rate: 0, buffer: "memory", buffer_options: {} } }
  its(:supervisor) { should be_a(Celluloid) }
  its(:buffer) { should be_a(FluQ::Buffer::Memory) }

  it 'should buffer events' do
    lambda {
      subject.on_events [FluQ::Event.new("tag", Time.now.to_i, {})]
    }.should change { subject.buffer.event_count }.by(1)
  end

end