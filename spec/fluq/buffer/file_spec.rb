require 'spec_helper'

describe Fluq::Buffer::File do

  let(:handler) { Fluq::Handler::Buffered.new buffer: "file", name: "file_test" }
  let(:root)    { Fluq.root.join("../scenario/tmp/buffers/file_test") }
  let(:event)   { Fluq::Event.new("tag", 1313131313, { "a" => "1" }) }

  subject       { handler.send(:buffer) }
  before        { FileUtils.rm_rf(root); FileUtils.mkdir_p(root) }

  def events(path)
    acc = []
    MessagePack::Unpacker.new.feed_each(File.read(path)) {|i| acc << i }
    acc
  end

  it_behaves_like "a buffer"
  it { should be_a(Fluq::Buffer::Base) }
  its(:current) { subject.value.should be_instance_of(File) }
  its(:current) { subject.value.path.should match /scenario\/tmp\/buffers\/file_test\/\d{10}\.[0-9a-f]{8}\.open$/  }

  describe "on initialize" do

    it "should create relevant paths" do
      FileUtils.rm_rf root
      lambda { subject }.should change {
        Fluq.root.join("../scenario/tmp/buffers/file_test").directory?
      }.to(true)
    end

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
    store = subject.send(:current).value
    10.times { subject.push(event) }
    subject.rotate!
    store.should be_closed
    events(store.path.sub(".open", ".closed")).should have(10).items
  end

  it "should flush safely" do
    5.times { subject.push(event) }
    subject.rotate!
    6.times { subject.push(event) }
    subject.rotate!
    7.times { subject.push(event) }

    events = []
    handler.should_receive(:on_flush).exactly(3).times.with {|e| events += e }

    lambda { subject.flush }.should change {
      [subject.size, subject.glob(:open).size, subject.glob(:closed).size]
    }.from([18, 1, 2]).to([0, 1, 0])
    events.should have(18).items
  end

  it "should rotate files safely" do
    t1 = Thread.new do
      sleep(0.01)
      subject.rotate!
    end
    t2 = Thread.new do
      5.times { subject.push(event) }
      t1.join
      5.times { subject.push(event) }
    end
    [t1, t2].each(&:join)

    open, closed = subject.glob(:open), subject.glob(:closed)
    open.should have(1).item
    closed.should have(1).item

    events(open[0]).should have(5).items
    events(closed[0]).should have(5).items
  end

end