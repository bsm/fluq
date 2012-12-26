require 'spec_helper'

describe FluQ::Buffer::File::Writer do

  let(:path)  { FluQ.root.join("tmp/buffers/file/writer") }
  let(:event) { FluQ::Event.new("some.tag", 1313131313, {}) }
  subject     { described_class.new(path, 1024) }
  before      { FileUtils.rm_rf(path) }

  def read(path)
    acc = []
    MessagePack::Unpacker.new.feed_each(File.read(path)) {|i| acc << i }
    acc
  end

  its(:root)    { should == path }
  its(:current) { should be_instance_of(Atomic) }
  its(:current) { subject.value.should be_instance_of(File) }
  its(:limit)   { should == 1024 }

  it "should create the path" do
    lambda { subject }.should change(path, :directory?).to(true)
  end

  it "should glob scoped files" do
    6.times {|i| subject.root.join("f.#{i}.closed").open("w") {} }
    2.times {|i| subject.root.join("f.#{i}.open").open("w") {} }
    counts = Hash.new(0)
    subject.glob(:closed) { counts[:closed] += 1 }
    subject.glob(:open) { counts[:open] += 1 }
    counts.should == { closed: 6, open: 2 }
  end

  it "should archive files" do
    source = subject.root.join("a.b.open")
    target = subject.root.join("a.b.closed")
    source.open("w") {}

    lambda { subject.archive(source).should == target }.should change {
      [source.exist?, target.exist?]
    }.from([true, false]).to([false, true])

    subject.archive(source).should be(nil)
    subject.archive(target).should be(nil)
  end

  it "should reserve files" do
    source = subject.root.join("a.b.closed")
    source.open("w") {}
    target = nil

    lambda { target = subject.reserve(source) }.should change { source.exist? }.to(false)
    target.should be_instance_of(Pathname)

    subject.reserve(source).should be(nil)
    subject.reserve(target).should be(nil)
  end

  it "should unreserve files" do
    source = subject.root.join("a.b.closed.abcdef")
    source.open("w") {}
    target = subject.root.join("a.b.closed")

    lambda { subject.unreserve(source).should == target }.should change {
      [source.exist?, target.exist?]
    }.from([true, false]).to([false, true])

    subject.unreserve(source).should be(nil)
    subject.unreserve(target).should be(nil)
  end

  it "should rotate files" do
    subject.write [event]
    lambda { subject.rotate }.should change {
      [subject.glob(:closed).size, subject.glob(:open).size]
    }.from([0, 1]).to([1, 1])

    subject.write [event]
    lambda { subject.rotate }.should change {
      [subject.glob(:closed).size, subject.glob(:open).size]
    }.from([1, 1]).to([2, 1])
  end

  it "should rotate only if needed" do
    subject.rotate.should be(false)
    subject.write [event]
    subject.rotate.should be(true)
    subject.rotate.should be(false)
  end

  it "should write events" do
    subject.write [event] * 5
    subject.rotate

    written = []
    subject.glob(:closed) do |path|
      written += read(path)
    end
    written.should == [event.to_a] * 5
  end

end