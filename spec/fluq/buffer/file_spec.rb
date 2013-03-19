require 'spec_helper'

describe FluQ::Buffer::File do

  let(:event) { FluQ::Event.new("some.tag", 1313131313, {}) }

  it           { should be_a(FluQ::Buffer::Base) }
  its(:config) { should == {max_size: 268435456, path: "tmp/buffers"} }
  its(:file)   { should be_instance_of(File) }
  its(:size)   { should == 0 }

  it "should generate unique paths" do
    Time.stub(now: Time.at(1313131313.45678))
    subject.file.path.should == FluQ.root.join("tmp/buffers/fluq-buffer-1313131313457.1").to_s
    described_class.new.file.path.should == FluQ.root.join("tmp/buffers/fluq-buffer-1313131313457.2").to_s
  end

  it "should write data" do
    100.times { subject.write(event.encode) }
    subject.size.should == 1600
  end

  it "should iterate over contents" do
    4.times { subject.write(event.encode) }
    subject.each_slice(2).to_a.should == [[event, event], [event, event]]
  end

  it "should prevent writes once buffer is 'drained'" do
    subject.write(event.encode)
    subject.to_a
    lambda { subject.write(event.encode) }.should raise_error(IOError, /closed/)
  end

  it "should close and unlink files" do
    subject.write(event.encode)
    lambda { subject.close }.should change { File.exists?(subject.file.path) }.to(false)
  end

end
