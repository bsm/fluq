require 'spec_helper'

describe FluQ::Event do

  subject { described_class.new :"some.tag", "1313131313", "a" => "v1", "b" => "v2" }

  it { should be_a(Hash) }
  its(:tag)       { should == "some.tag" }
  its(:timestamp) { should == 1313131313 }
  its(:time)      { should be_instance_of(Time) }
  its(:time)      { should be_utc }
  its(:to_a)      { should == ["some.tag", 1313131313, "a" => "v1", "b" => "v2"] }
  its(:encode)    { should == "\x93\xA8some.tag\xCEND\xCB1\x82\xA1a\xA2v1\xA1b\xA2v2".force_encoding(Encoding::BINARY) }
  its(:inspect)   { should == %(["some.tag", 1313131313, {"a"=>"v1", "b"=>"v2"}]) }

  it "should be comparable" do
    subject.should == { "a" => "v1", "b" => "v2" }
    subject.should == ["some.tag", 1313131313, "a" => "v1", "b" => "v2"]
    [subject].should == [{ "a" => "v1", "b" => "v2" }]
    [subject, subject].should == [["some.tag", 1313131313, "a" => "v1", "b" => "v2"]] * 2
  end

end