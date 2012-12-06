require 'spec_helper'

describe FluQ::Input::Socket do

  subject { described_class.new(bind: "tcp://localhost:7654") }
  after   { subject.terminate }

  it { should be_a(described_class) }

  it 'should require bind option' do
    lambda { described_class.new }.should raise_error(ArgumentError, /No URL to bind/)
  end

  it 'should bind only to tcp or unix' do
    lambda { described_class.new(bind: 'udp://1234') }.should raise_error(URI::InvalidURIError)
  end

end
