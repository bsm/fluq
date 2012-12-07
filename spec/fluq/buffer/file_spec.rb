require 'spec_helper'

describe FluQ::Buffer::File do

  let(:handler) { FluQ::Handler::Buffered.new buffer: "file", name: "file_test" }
  let(:root)    { FluQ.root.join("../scenario/tmp/buffers/file_test") }
  let(:event)   { FluQ::Event.new("tag", 1313131313, { "a" => "1" }) }

  subject       { handler.send(:buffer) }
  before        { FileUtils.rm_rf(root); FileUtils.mkdir_p(root) }

  def events(path)
    acc = []
    MessagePack::Unpacker.new.feed_each(File.read(path)) {|i| acc << i }
    acc
  end

  it_behaves_like "a buffer"
  it { should be_a(FluQ::Buffer::Base) }
  its(:current) { should be_instance_of(File) }
  its(:current) { subject.path.should match /scenario\/tmp\/buffers\/file_test\/\d{10}\.[0-9a-f]{8}\.open$/  }
  its(:root)    { should be_instance_of(Pathname) }
  its(:root)    { should == FluQ.root.join("tmp/buffers/file_test") }

  it 'can have a custom root' do
    described_class.new(handler, path: "log/my_buf").root.should == FluQ.root.join("log/my_buf")
  end

  describe "on initialize" do

    it "should create relevant paths" do
      FileUtils.rm_rf root
      lambda { subject }.should change {
        FluQ.root.join("../scenario/tmp/buffers/file_test").directory?
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
    store = subject.send(:current)
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
    }.from([18, 1, 2]).to([0, 0, 0])
    events.should have(18).items
  end

  it "should rotate files safely" do
    lambda {
      t1 = Thread.new { 8.times { subject.rotate! } }
      t2 = Thread.new { 128.times { subject.push(event) } }
      [t1, t2].each(&:join)
    }.should_not raise_error

    total = (subject.glob(:open) + subject.glob(:closed)).inject(0) {|sum, path| sum + events(path).size }
    total.should == 128
  end

end