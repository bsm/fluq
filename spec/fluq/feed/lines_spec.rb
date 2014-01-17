require 'spec_helper'

describe FluQ::Feed::Lines do

  subject { FluQ::Feed::Json.new }

  it { should be_a(described_class) }
  it { should be_a(FluQ::Feed::Base) }

  it 'should parse' do
    subject.parse(%({"a":1})).should have(1).item
    subject.parse(%({"a":1}\n{"b":2}\n\n{"c":3}\n)).should have(3).items
  end

  it 'should deal with partials' do
    subject.parse(%({"a":1}\n{"b")).should == [{"a"=>1}]
    subject.parse(%(:2}\n)).should == [{"b"=>2}]
  end

end
