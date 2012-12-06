require 'spec_helper'

describe Fluq::Input::Socket do
  it 'should require :bind option' do
    lambda { described_class.new }.should raise_error(ArgumentError, /No URL to bind/)
    described_class.new(bind: "tcp://localhost:7654").should be_a(described_class)
  end

  it 'should ensure :bind is only tcp or unix' do
    lambda { described_class.new(bind: 'udp://1234') }.should raise_error(URI::InvalidURIError)
  end

end
