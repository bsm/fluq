require 'spec_helper'

describe FluQ::Input::Socket::Connection do

  let(:event)    { FluQ::Event.new("some.tag", 1313131313, {}) }
  let!(:handler) { reactor.register FluQ::Handler::Test }
  let(:timer)    { mock("Timer", cancel: true) }
  subject        { described_class.new(Time.now.to_i, reactor) }
  before         { EM.stub add_periodic_timer: timer }

  it { should be_a(EM::Connection) }
  its(:queue) { should be_instance_of(Queue) }

  it 'should recover connection errors' do
    subject.queue.should_receive(:<<).and_raise(RuntimeError)
    FluQ.logger.should_receive(:crash)
    subject.receive_data [event, event].map(&:encode).join
  end

  it 'should queue incoming data' do
    subject.receive_data [event, event].map(&:encode).join
    subject.receive_data [event, event, event].map(&:encode).join
    subject.queue.should have(5).items
  end

  it 'should flush queue when idle' do
    subject.receive_data [event, event].map(&:encode).join
    subject.receive_data [event, event, event].map(&:encode).join
    subject.receive_data [event].map(&:encode).join
    lambda {
      subject.send(:flush!)
    }.should change { subject.queue.size }.from(6).to(0)
    FluQ::Testing.wait_until { handler.events.size > 5 }
    handler.should have(6).events
  end

end
