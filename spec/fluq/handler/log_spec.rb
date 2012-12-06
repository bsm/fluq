require 'spec_helper'

describe Fluq::Handler::Log do

  let(:event) do
    Fluq::Event.new("my.special.tag", 1313131313, { "a" => "1" })
  end
  let(:root)    { Fluq.root.join("../scenario/log/raw") }
  before        { FileUtils.rm_rf(root); FileUtils.mkdir_p(root) }


  it { should be_a(Fluq::Handler::Base) }
  its(:config) { subject.keys.should =~ [:convert, :path, :pattern, :rewrite] }

  it 'should log events' do
    subject.on_event(event)
    file = root.join("my/special/tag/20110812/06.log")
    file.should be_file
    file.read.should == %(my.special.tag\t1313131313\t{"a":"1"}\n)
  end

  it 'can have custom conversions' do
    subject = described_class.new convert: lambda {|e| e.merge(ts: e.timestamp).map {|k,v| "#{k}=#{v}" }.join(',') }
    subject.on_event(event)
    root.join("my/special/tag/20110812/06.log").read.should == "a=1,ts=1313131313\n"
  end

  it 'can rewrite tags' do
    subject = described_class.new rewrite: lambda {|t| t.split('.').reverse.first(2).join(".") }
    subject.on_event(event)
    root.join("tag.special/20110812/06.log").should be_file
  end

end