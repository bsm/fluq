require 'spec_helper'

describe FluQ::Input::Socket do

  let(:event) { FluQ::Event.new("some.tag", 1313131313, {}) }
  let!(:input) { described_class.new(reactor, bind: "tcp://127.0.0.1:26712") }
  let!(:handler) { reactor.register FluQ::Handler::Test }

  subject { input }
  after   { input.terminate }

  it { should be_a(FluQ::Input::Base) }
  it { should be_a(Celluloid) }

  it 'should require bind option' do
    lambda { described_class.new(reactor) }.should raise_error(ArgumentError, /No URL to bind/)
  end

  it 'should bind only to tcp or unix' do
    lambda { described_class.new(reactor, bind: 'udp://1234') }.should raise_error(URI::InvalidURIError)
  end

  it 'should handle requests' do
    client = TCPSocket.open("127.0.0.1", 26712)
    client.write event.encode
    client.close

    FluQ::Testing.wait_until { handler.events.size > 0 }
    handler.events.should == [event]
  end

end
