require 'spec_helper'

describe FluQ::Handler::Log do

  let(:event) do
    FluQ::Event.new("my.special.tag", 1313131313, { "a" => "1" })
  end
  let(:root)    { FluQ.root.join("../scenario/log/raw") }
  let(:plain)   { described_class.new(path: "log/raw/%t/%Y%m%d/%H.log") }
  before        { FileUtils.rm_rf(root); FileUtils.mkdir_p(root) }

  def read_gz(file)
    content = nil
    Zlib::GzipReader.open(file) {|gz| content = gz.read }
    content
  end

  it { should be_a(FluQ::Handler::Base) }
  its(:config) { subject.keys.should =~ [:convert, :path, :pattern, :rewrite] }

  it 'should log events' do
    subject.on_event(event)
    subject.finalize
    file = root.join("my/special/tag/20110812/06.log.gz")
    file.should be_file
    read_gz(file).should == %(my.special.tag\t1313131313\t{"a":"1"}\n)
  end

  it "can log plain text" do
    plain.on_event(event)
    plain.finalize
    root.join("my/special/tag/20110812/06.log").read.should == %(my.special.tag\t1313131313\t{"a":"1"}\n)
  end

  it 'can have custom conversions' do
    subject = described_class.new convert: lambda {|e| e.merge(ts: e.timestamp).map {|k,v| "#{k}=#{v}" }.join(',') }
    subject.on_event(event)
    subject.finalize
    read_gz(root.join("my/special/tag/20110812/06.log.gz")).should == "a=1,ts=1313131313\n"
  end

  it 'can rewrite tags' do
    subject = described_class.new rewrite: lambda {|t| t.split('.').reverse.first(2).join(".") }
    subject.on_event(event)
    root.join("tag.special/20110812/06.log.gz").should be_file
  end

  it 'should cache file handles' do
    f1, f2 = root.join("my/special/tag/20110812/06.log"), root.join("other/tag/20080530/04.log")

    lambda {
      plain.on_event(event)
      plain.on_event(FluQ::Event.new("other.tag", 1212121212, {}))
    }.should change { plain.io_cache.keys.sort }.from([]).to([f1.to_s, f2.to_s])

    f1.should be_file
    f2.should be_file
  end

  it 'should update file handles on events' do
    path = root.join("my/special/tag/20110812/06.log").to_s
    plain.on_event(event)
    plain.io_cache[path].ts = 0
    lambda { plain.on_event(event) }.should change { plain.io_cache[path].ts }.to(Time.now.to_i)
  end

  it 'should periodically expire handles' do
    plain.on_event(event)
    lambda { plain.send(:expire_cache!) }.should_not change { plain.io_cache }

    plain.io_cache.values.each {|v| v.ts = Time.now.to_i - 60 }
    lambda { plain.send(:expire_cache!) }.should change { plain.io_cache }.to({})
  end

end
