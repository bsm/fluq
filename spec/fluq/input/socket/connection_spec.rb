require 'spec_helper'

describe FluQ::Input::Socket::Connection do

  let(:event)    { FluQ::Event.new("some.tag", 1313131313, {}) }
  let(:input)    { FluQ::Input::Socket.new reactor, bind: "tcp://127.0.0.1:26712" }
  before         { EventMachine.stub(:set_comm_inactivity_timeout) }
  subject        { described_class.new(Time.now.to_i, input) }

  it { should be_a(EM::Connection) }

  it 'should set a timeout' do
    EventMachine.should_receive(:set_comm_inactivity_timeout).with(instance_of(Fixnum), 60)
    subject
  end

  it 'should handle data' do
    subject.receive_data [event, event].map(&:to_msgpack).join
    subject.send(:buffer).size.should == 38
  end

  it 'should flush when data transfer is complete' do
    subject.receive_data [event, event].map(&:to_msgpack).join
    input.should_receive(:flush!).with(instance_of(FluQ::Buffer::File))
    subject.unbind
  end

  it 'should recover connection errors' do
    reactor.should_receive(:process).and_raise(Errno::ECONNRESET)
    FluQ.logger.should_receive(:crash)
    subject.receive_data [event, event].map(&:to_msgpack).join
    subject.unbind
  end

end
