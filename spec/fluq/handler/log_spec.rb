require 'spec_helper'

describe FluQ::Handler::Log do

  let(:event)  { FluQ::Event.new({"a" => "1"}, 1313131313) }
  let(:root)   { FluQ.root.join("../scenario/log/raw") }
  before       { FileUtils.rm_rf(root); FileUtils.mkdir_p(root) }

  it { should be_a(FluQ::Handler::Base) }
  its("config.keys") { should =~ [:convert, :path, :cache_max, :cache_ttl, :timeout] }

  it "can log events" do
    subject.on_events [event]
    subject.pool.each_key {|k| subject.pool[k].flush }
    root.join("20110812.log").read.should == %(1313131313\t{"a":"1"}\n)
  end

  it 'can have custom conversions' do
    subject = described_class.new convert: ->e { e.merge(ts: e.timestamp).map {|k,v| "#{k}=#{v}" }.join(',') }
    subject.on_events [event]
    subject.pool.each_key {|k| subject.pool[k].flush }
    root.join("20110812.log").read.should == "a=1,ts=1313131313\n"
  end

  it 'can rewrite events' do
    subject = described_class.new rewrite: ->e { e["a"].to_i * 1000 }, path: "log/raw/%Y%m/%t.log"
    subject.on_events [event]
    root.join("201108/1000.log").should be_file
  end

  it 'should not fail on temporary file errors' do
    subject.on_events [event]
    subject.pool.each_key {|k| subject.pool[k].close }
    subject.on_events [event]
    subject.pool.each_key {|k| subject.pool[k].flush }
    root.join("20110812.log").read.should have(2).lines
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
