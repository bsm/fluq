require 'spec_helper'

describe FluQ::Event do

  subject { described_class.new({"a" => "v1", "b" => "v2"}, "1313131313") }

  it { should be_a(Hash) }
  its(:meta)       { should == {} }
  its(:timestamp)  { should == 1313131313 }
  its(:time)       { should be_instance_of(Time) }
  its(:time)       { should be_utc }

  it "should be comparable" do
    other = described_class.new({"a" => "v1", "b" => "v2"}, "1313131313")

    subject.should == other
    other.meta[:some] = "thing"
    subject.should == other
    other["c"] = "d"
    subject.should_not == other
    subject.should_not == described_class.new({"a" => "v1", "b" => "v2"}, "1313131312")
  end

  it "should be inspectable" do
    subject.inspect.should == %(#<FluQ::Event(1313131313) data:{"a"=>"v1", "b"=>"v2"} meta:{}>)
    subject.meta[:some] = "thing"
    subject.inspect.should == %(#<FluQ::Event(1313131313) data:{"a"=>"v1", "b"=>"v2"} meta:{:some=>"thing"}>)
  end

end
