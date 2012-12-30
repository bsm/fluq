require 'spec_helper'

describe FluQ::Buffer::File do

  let(:handler) { FluQ::Handler::Buffered.new reactor, name: "file_test", buffer: "file" }
  let(:root)    { FluQ.root.join("../scenario/tmp/buffers/file_test") }
  let(:event)   { FluQ::Event.new("tag", 1313131313, { "a" => "1" }) }
  let(:writer)  { subject.send :writer }

  subject       { handler.send(:buffer) }
  before        { FileUtils.rm_rf(root); FileUtils.mkdir_p(root) }

  def events(*paths)
    paths.map do |path|
      FluQ::Event::Unpacker.new(File.open(path)).to_a
    end.flatten
  end

  def total_events
    (writer.glob(:open) + writer.glob(:closed)).map {|path| events(path).size }.inject(0, :+)
  end

  it_behaves_like "a buffer"
  it { should be_a(FluQ::Buffer::Base) }
  its(:writer) { should be_a(described_class::Writer) }
  its(:config) { should == { path: "tmp/buffers/file_test", max_size: 134217728 } }

  describe "on initialize" do

    it "should close open files" do
      root.join("2012121212.abcd.open").open("wb") {|f| f.write(event.encode) }
      lambda { subject }.should change {
        [root.join("2012121212.abcd.open").file?, root.join("2012121212.abcd.closed").file?]
      }.from([true, false]).to([false, true])
    end

    it "should revert reserved files" do
      root.join("2012121212.abcd.closed.abcdef").open("wb") {|f| f.write(event.encode) }
      lambda { subject }.should change {
        [root.join("2012121212.abcd.closed.abcdef").file?, root.join("2012121212.abcd.closed").file?]
      }.from([true, false]).to([false, true])
    end

  end

  it "should accept new events" do
    subject.concat [event] * 10
    writer.rotate
    events(*Dir[root.join("*")]).should have(10).items
  end

  it "should flush safely" do
    subject.concat [event] * 5
    writer.rotate
    subject.concat [event] * 6
    writer.rotate
    subject.concat [event] * 7

    events = []
    handler.should_receive(:on_flush).exactly(3).times.with {|e| events += e }

    lambda {
      subject.flush
      FluQ::Testing.wait_until { events.size > 17 }
    }.should change {
      [subject, writer.glob(:open), writer.glob(:closed)].map(&:size)
    }.from([18, 1, 2]).to([0, 1, 0])
    events.should have(18).items
    events.first.should be_a(FluQ::Event)
    events.first.should == event
  end

  it "should rotate files safely" do
    lambda {
      [ Thread.new { subject.concat [event] * 16 },
        Thread.new { subject.concat [event] * 16 },
        Thread.new { subject.concat [event] * 16 },
        Thread.new { subject.concat [event] * 16 },
        Thread.new { subject.concat [event] * 16 },
        Thread.new { subject.concat [event] * 16 },
        Thread.new { subject.concat [event] * 16 },
        Thread.new { subject.concat [event] * 16 },
        Thread.new { 8.times { writer.rotate } }
      ].each(&:join)
    }.should_not raise_error

    FluQ::Testing.wait_until { total_events > 127 }
    total_events.should == 128
  end
end
