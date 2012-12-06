require 'spec_helper'

describe FluQ::Handler::Log do

  let(:event) do
    FluQ::Event.new("my.special.tag", 1313131313, { "a" => "1" })
  end
  let(:root)    { FluQ.root.join("../scenario/log/raw") }
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
    file = root.join("my/special/tag/20110812/06.log.gz")
    file.should be_file
    read_gz(file).should == %(my.special.tag\t1313131313\t{"a":"1"}\n)
  end

  it "can log plain text" do
    plain = described_class.new(path: "log/raw/%t/%Y%m%d/%H.log")
    plain.on_event(event)
    root.join("my/special/tag/20110812/06.log").read.should == %(my.special.tag\t1313131313\t{"a":"1"}\n)
  end

  it 'can have custom conversions' do
    subject = described_class.new convert: lambda {|e| e.merge(ts: e.timestamp).map {|k,v| "#{k}=#{v}" }.join(',') }
    subject.on_event(event)
    read_gz(root.join("my/special/tag/20110812/06.log.gz")).should == "a=1,ts=1313131313\n"
  end

  it 'can rewrite tags' do
    subject = described_class.new rewrite: lambda {|t| t.split('.').reverse.first(2).join(".") }
    subject.on_event(event)
    root.join("tag.special/20110812/06.log.gz").should be_file
  end

end