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

  it 'should recover connection errors' do
    FluQ::Event::Unpacker.should_receive(:new).and_raise(Errno::ECONNRESET)

    client = TCPSocket.open("127.0.0.1", 26712)
    client.write event.encode
    client.close
    sleep(0.01)

    input.should be_alive
  end

  it 'should handle requests' do
    client = TCPSocket.open("127.0.0.1", 26712)
    client.write event.encode
    client.close

    FluQ::Testing.wait_until { handler.events.size > 0 }
    handler.should have(1).events
  end

  it 'should handle large parallel requests' do
    (0...2).map do
      Thread.new do
        client = TCPSocket.open("127.0.0.1", 26712)
        client.write (0...500).map { event.encode }.join
        client.close
      end
    end.each(&:join)

    FluQ::Testing.wait_until { handler.events.size == 1000 }
    handler.should have(1000).events
  end

end
