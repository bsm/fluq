require 'spec_helper'

describe FluQ::Feed::Msgpack do

  let(:data) { ([{"a" => "b"}] * 3).map(&:to_msgpack).join }

  it { should be_a(FluQ::Feed::Base) }

  it 'should parse' do
    events = subject.parse(data)
    events.should have(3).items
    events.first.timestamp.should be_within(5).of(Time.now.to_i)
    events.first.should == FluQ::Event.new({"a" => "b"}, events.first.timestamp)
  end

  it 'should log invalid inputs' do
    subject.logger.should_receive(:warn).at_least(:once)
    events = subject.parse data + "NOTMP" + data
    events.should have(6).items
  end

end
