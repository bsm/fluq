require 'spec_helper'

describe FluQ::Format::Msgpack do

  let(:data) { ([{"a" => "b"}] * 3).map {|h| MessagePack.pack(h) }.join }

  it { should be_a(FluQ::Format::Base) }

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
