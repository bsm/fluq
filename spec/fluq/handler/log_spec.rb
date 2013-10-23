require 'spec_helper'

describe FluQ::Handler::Log do

  let(:event) do
    FluQ::Event.new("my.special.tag", 1313131313, { "a" => "1" })
  end
  let(:root) { FluQ.root.join("../scenario/log/raw") }
  subject    { described_class.new reactor }
  before     { FileUtils.rm_rf(root); FileUtils.mkdir_p(root) }

  it { should be_a(FluQ::Handler::Base) }
  its("config.keys") { should =~ [:convert, :path, :pattern, :rewrite, :cache_max, :cache_ttl, :timeout] }

  it "can log events" do
    subject.on_events [event]
    subject.pool.each_key {|k| subject.pool[k].flush }
    root.join("my/special/tag/20110812/06.log").read.should == %(my.special.tag\t1313131313\t{"a":"1"}\n)
  end

  it 'can have custom conversions' do
    subject = described_class.new reactor, convert: lambda {|e| e.merge(ts: e.timestamp).map {|k,v| "#{k}=#{v}" }.join(',') }
    subject.on_events [event]
    subject.pool.each_key {|k| subject.pool[k].flush }
    root.join("my/special/tag/20110812/06.log").read.should == "a=1,ts=1313131313\n"
  end

  it 'can rewrite tags' do
    subject = described_class.new reactor, rewrite: lambda {|t| t.split('.').reverse.first(2).join(".") }
    subject.on_events [event]
    root.join("tag.special/20110812/06.log").should be_file
  end

  it 'should not fail on temporary file errors' do
    subject.on_events [event]
    subject.pool.each_key {|k| subject.pool[k].close }
    subject.on_events [event]
    subject.pool.each_key {|k| subject.pool[k].flush }
    root.join("my/special/tag/20110812/06.log").read.should have(2).lines
  end

  describe described_class::FilePool do
    subject    { described_class::FilePool.new(max_size: 2) }
    let(:path) { root.join("a.log") }

    it { should be_a(TimedLRU) }

    it 'should open files' do
      lambda {
        subject.open(path).should be_instance_of(File)
      }.should change { subject.keys }.from([]).to([path.to_s])
    end

    it 'should re-use open files' do
      fd = subject.open(path)
      lambda {
        subject.open(path).should be(fd)
      }.should_not change { subject.keys }
    end

    it 'should auto-close files' do
      fd = subject.open(path)
      fd.should be_autoclose
    end

  end

end
