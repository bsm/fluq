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

  it { should be_a(Celluloid) }
  its(:root)    { should == path }
  its(:current) { should be_instance_of(File) }
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

    lambda { subject.archive(source) }.should change {
      [source.exist?, target.exist?]
    }.from([true, false]).to([false, true])
  end

  it "should rotate files" do
    subject.send(:write, event)
    lambda { subject.send(:rotate) }.should change {
      [subject.glob(:closed).size, subject.glob(:open).size]
    }.from([0, 1]).to([1, 0])

    subject.send(:write, event)
    lambda { subject.send(:rotate) }.should change {
      [subject.glob(:closed).size, subject.glob(:open).size]
    }.from([1, 1]).to([2, 0])
  end

  it "should rotate only if needed" do
    subject.send(:rotate).should be(false)
    subject.send(:write, event)
    subject.send(:rotate).should be(true)
    subject.send(:rotate).should be(false)
  end

  it "should write events" do
    5.times { subject.send(:write, event) }
    subject.rotate

    written = []
    subject.glob(:closed) do |path|
      written += read(path)
    end
    written.should == [event.to_a] * 5
  end

  it "should rotate files safely" do
    lambda {
      t1 = Thread.new { 64.times { subject.write!(event) } }
      t2 = Thread.new { 8.times { subject.rotate! } }
      t3 = Thread.new { 64.times { subject.write!(event) } }
      [t1, t2, t3].each(&:join)
    }.should_not raise_error

    total = (subject.glob(:open) + subject.glob(:closed)).map {|n| read(n).size }.inject(0, :+)
    total.should == 128
  end

end