require 'spec_helper'

describe FluQ::Buffer::File do

  let(:event) { FluQ::Event.new("some.tag", 1313131313, {}) }

  it           { should be_a(FluQ::Buffer::Base) }
  its(:config) { should == {max_size: 268435456, path: "tmp/buffers"} }
  its(:file)   { should be_instance_of(File) }
  its(:size)   { should == 0 }

  it "should return a name" do
    Time.stub(now: Time.at(1313131313.45678))
    subject.name.should == "file-fb-1313131313457.1"
  end

  it "should generate unique paths" do
    Time.stub(now: Time.at(1313131313.45678))
    subject.file.path.should == FluQ.root.join("tmp/buffers/fb-1313131313457.1").to_s
    described_class.new.file.path.should == FluQ.root.join("tmp/buffers/fb-1313131313457.2").to_s
  end

  it "should write data" do
    data = event.to_msgpack
    100.times { subject.write(data) }
    subject.size.should == 1900
  end

  it "should drain contents" do
    4.times { subject.write(event.to_msgpack) }
    subject.drain do |io|
      io.read.should == ([event.to_msgpack] * 4).join
    end
  end

  it "should prevent writes once buffer is 'drained'" do
    subject.write(event.to_msgpack)
    subject.drain {|*| }
    lambda { subject.write(event.to_msgpack) }.should raise_error(IOError, /closed/)
  end

  it "should close and unlink files" do
    subject.write(event.to_msgpack)
    lambda { subject.close }.should change { File.exists?(subject.file.path) }.to(false)
  end

end
