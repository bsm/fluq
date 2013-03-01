require 'spec_helper'

describe FluQ::Input::Socket do

  def input(reactor)
    described_class.new(reactor, bind: "tcp://127.0.0.1:26712")
  end

  let(:event)   { FluQ::Event.new("some.tag", 1313131313, {}) }
  let(:timer)   { mock("Timer", cancel: true) }
  subject       { input(reactor) }

  it { should be_a(FluQ::Input::Base) }

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
    with_reactor do |reactor|
      reactor.listen described_class, bind: "udp://127.0.0.1:26713"
      client = UDPSocket.new
      client.send event.encode, 0, "127.0.0.1", 26713
      client.close
    end
  end

end
