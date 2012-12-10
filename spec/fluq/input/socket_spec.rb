require 'spec_helper'

describe FluQ::Input::Socket do

  subject { described_class.new(reactor, bind: "tcp://localhost:7654") }
  after   { subject.terminate }

  it { should be_a(FluQ::Input::Base) }

  it 'should require bind option' do
    lambda { described_class.new(reactor) }.should raise_error(ArgumentError, /No URL to bind/)
  end

  it 'should bind only to tcp or unix' do
    lambda { described_class.new(reactor, bind: 'udp://1234') }.should raise_error(URI::InvalidURIError)
  end

end
