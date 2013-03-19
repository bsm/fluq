require 'spec_helper'

describe FluQ::Input::Socket do

  let(:event)   { FluQ::Event.new("some.tag", 1313131313, {}) }

  def input(reactor)
    described_class.new(reactor, bind: "tcp://127.0.0.1:26712")
  end

  subject { input(reactor) }
  it { should be_a(FluQ::Input::Base) }
  its(:name)   { should == "socket (tcp://127.0.0.1:26712)" }
  its(:config) { should == {buffer: "file", buffer_options: {}, bind: "tcp://127.0.0.1:26712"} }

  it 'should require bind option' do
    lambda { described_class.new(reactor) }.should raise_error(ArgumentError, /No URL to bind/)
  end

  it 'should handle requests' do
    with_reactor do |reactor|
      server = input(reactor)
      lambda { TCPSocket.open("127.0.0.1", 26712) }.should raise_error(Errno::ECONNREFUSED)

      server.run
      client = TCPSocket.open("127.0.0.1", 26712)

      client.write event.encode
      client.close
    end
  end

  it 'should support UDP' do
    h = nil
    with_reactor do |reactor|
      h = reactor.register FluQ::Handler::Test
      reactor.listen described_class, bind: "udp://127.0.0.1:26713"
      client = UDPSocket.new
      client.send event.encode, 0, "127.0.0.1", 26713
      client.close
    end
    h.should have(1).events
  end

end
