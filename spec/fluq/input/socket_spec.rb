require 'spec_helper'

describe FluQ::Input::Socket do

  let(:event)   { {a: 1, b: 2} }
  let(:actors)  { [] }

  def input(opts = {})
    actor = described_class.new [[FluQ::Handler::Test]], opts
    actors << actor
    actor
  end

  def wait_for(server)
    30.times do
      break if server.listening?
      sleep(0.01)
    end
  end

  subject { input bind: "tcp://127.0.0.1:26712", format: "msgpack" }
  after   { actors.each &:terminate }

  it { should be_a(FluQ::Input::Base) }
  its(:name)   { should == "socket (tcp://127.0.0.1:26712)" }
  its(:config) { should == {format: "msgpack", format_options: {}, bind: "tcp://127.0.0.1:26712"} }

  it 'should require bind option' do
    -> { input }.should raise_error(ArgumentError, /No URL to bind/)
  end

  it 'should handle requests' do
    wait_for(subject)
    client = TCPSocket.open("127.0.0.1", 26712)
    client.write MessagePack.pack(event)
    client.close
    subject.worker.should have(1).handlers
    subject.worker.handlers.first.should have(1).events
  end

  it 'should support UDP' do
    udp = input bind: "udp://127.0.0.1:26713", format: "msgpack"
    wait_for(udp)

    client = UDPSocket.new
    client.send MessagePack.pack(event), 0, "127.0.0.1", 26713
    client.close
    udp.worker.should have(1).handlers
    udp.worker.handlers.first.should have(1).events
  end

end
