require 'spec_helper'

describe FluQ::Input::Socket do

  # around do |example|
  #   with_reactor do |reactor|
  #     @reactor = reactor
  #     example.run
  #   end
  # end

  let(:event)   { FluQ::Event.new("some.tag", 1313131313, {}) }

  def input(reactor)
    described_class.new(reactor, bind: "tcp://127.0.0.1:26712")
  end

  subject { input(reactor) }

  it { should be_a(FluQ::Input::Base) }

  it 'should require bind option' do
    lambda { described_class.new(reactor) }.should raise_error(ArgumentError, /No URL to bind/)
  end

  it 'should bind only to tcp or unix' do
    lambda { described_class.new(reactor, bind: 'udp://1234') }.should raise_error(URI::InvalidURIError)
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

end
