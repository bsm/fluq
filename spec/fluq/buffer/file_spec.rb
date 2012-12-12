require 'spec_helper'

describe FluQ::Buffer::File do

  let(:handler) { FluQ::Handler::Buffered.new name: "file_test", buffer: "file" }
  let(:root)    { FluQ.root.join("../scenario/tmp/buffers/file_test") }
  let(:event)   { FluQ::Event.new("tag", 1313131313, { "a" => "1" }) }
  let(:writer)  { subject.send :writer }

  subject       { handler.send(:buffer) }
  before        { FileUtils.rm_rf(root); FileUtils.mkdir_p(root) }

  # Force file rotation
  def rotate!
    writer.send(:rotate)
  end

  def events(path)
    acc = []
    MessagePack::Unpacker.new.feed_each(File.read(path)) {|i| acc << i }
    acc
  end

  def total_events
    (writer.glob(:open) + writer.glob(:closed)).map {|path| events(path).size }.inject(0, :+)
  end

  it_behaves_like "a buffer"
  it { should be_a(FluQ::Buffer::Base) }
  its(:supervisor) { should be_a(Celluloid::SupervisionGroup) }
  its(:writer) { should be_a(described_class::Writer) }
  its(:config) { should == { path: "tmp/buffers/file_test", max_size: 134217728 } }

  describe "on initialize" do

    it "should close open files" do
      root.join("2012121212.abcd.open").open("wb") {|f| f.write(event.encode) }
      lambda { subject }.should change {
        [root.join("2012121212.abcd.open").file?, root.join("2012121212.abcd.closed").file?]
      }.from([true, false]).to([false, true])
    end

    it "should count previous events" do
      root.join("2012121212.abcd.open").open("wb") {|f| f.write(event.encode) }
      root.join("2012121212.bcde.closed").open("wb") {|f| f.write(event.encode * 2) }
      subject.size.should == 3
    end

  end

  it "should accept new events" do
    10.times { subject.push(event) }
    rotate!
    events(Dir[root.join("*")].first).should have(10).items
  end

  it "should flush safely" do
    5.times { subject.push(event) }
    rotate!
    6.times { subject.push(event) }
    rotate!
    7.times { subject.push(event) }

    events = []
    handler.should_receive(:on_flush).exactly(3).times.with {|e| events += e }

    lambda { subject.flush }.should change {
      [subject, writer.glob(:open), writer.glob(:closed)].map(&:size)
    }.from([18, 1, 2]).to([0, 0, 0])
    events.should have(18).items
    events.first.should be_a(FluQ::Event)
    events.first.should == event
  end

  it "should rotate files safely" do
    lambda {
      t1 = Thread.new { 64.times { subject.push(event) } }
      t2 = Thread.new { 8.times { rotate! } }
      t3 = Thread.new { 64.times { subject.push(event) } }
      [t1, t2, t3].each(&:join)
    }.should_not raise_error

    FluQ::Testing.wait_until { total_events > 127 }
    total_events.should == 128
  end

end
