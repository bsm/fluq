require 'spec_helper'

describe FluQ::Input::Socket::Connection do

  let(:event)    { FluQ::Event.new("some.tag", 1313131313, {}) }
  let!(:handler) { reactor.register FluQ::Handler::Test }
  subject        { described_class.new(Time.now.to_i, reactor) }

  it { should be_a(EM::Connection) }

  it 'should handle data' do
    subject.receive_data [event, event].map(&:encode).join
    subject.send(:buffer).size.should == 32
  end

  it 'should process when data transfer is complete' do
    subject.receive_data [event, event].map(&:encode).join
    subject.unbind
    handler.should have(2).events
  end

  it 'should recover connection errors' do
    reactor.should_receive(:process).and_raise(Errno::ECONNRESET)
    FluQ.logger.should_receive(:crash)
    subject.receive_data [event, event].map(&:encode).join
    subject.unbind
  end

end
