require 'spec_helper'

describe FluQ::Event do

  subject { described_class.new "_tag" => "some.tag", "_ts" => "1313131313", "a" => "v1", "b" => "v2" }

  it { should be_a(Hash) }
  it { should == { "_tag" => "some.tag", "_ts" => 1313131313, "a" => "v1", "b" => "v2" } }
  its(:tag)       { should == "some.tag" }
  its(:timestamp) { should == 1313131313 }
  its(:time)      { should be_instance_of(Time) }
  its(:time)      { should be_utc }
  its(:encode)    { should == Hash.new.update(subject).to_msgpack }
  its(:to_s)      { should == MultiJson.dump(Hash.new.update(subject)) }
  its(:inspect)   { should == Hash.new.update(subject).inspect }

  it 'should normalize events' do
    Time.stub now: Time.at(1414141414)
    described_class.new.should == { "_tag" => "", "_ts" => 1414141414 }
    described_class.new("_tag" => :any, "_ts" => 1313131313.123).should == { "_tag" => "any", "_ts" => 1313131313 }
    described_class.new("_tag" => :any, "_ts" => "1313131313").should == { "_tag" => "any", "_ts" => 1313131313 }
    described_class.new("_tag" => :any, "_ts" => Time.now).should == { "_tag" => "any", "_ts" => 1414141414 }
  end

end