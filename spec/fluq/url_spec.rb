require 'spec_helper'

describe FluQ::URL do

  it "should parse URLs" do
    described_class.parse("tcp://localhost:1234/", ["tcp"]).should be_instance_of(URI::Generic)
    described_class.parse("tcp://localhost:1234/", ["tcp", "unix"]).should be_instance_of(URI::Generic)
  end

  it "should ensure correct schemes" do
    lambda {
      described_class.parse("tcp://localhost:1234/", ["udp", "unix"])
    }.should raise_error(URI::InvalidURIError)
  end

end