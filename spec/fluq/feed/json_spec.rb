require 'spec_helper'

describe FluQ::Feed::Json do

  let(:data) { %({"a":"b"}\n{"a":"b"}\n{"a":"b"}\n) }

  it { should be_a(FluQ::Feed::Lines) }

  it 'should parse' do
    events = subject.parse(data)
    events.should have(3).items
    events.first.timestamp.should be_within(5).of(Time.now.to_i)
    events.first.should == FluQ::Event.new({"a" => "b"}, events.first.timestamp)
  end

  it 'should log invalid inputs' do
    subject.logger.should_receive(:warn).once
    events = subject.parse data + %(NOTJSON\n{"a":"b"}\n\n{"a":"b"})
    events.should have(5).items
  end

end
