require 'spec_helper'

describe FluQ::Feed::Msgpack do

  let(:buffer) { FluQ::Buffer::Base.new }
  let(:event)  { FluQ::Event.new("some.tag", 1313131313, "a" => "b") }

  before do
    io = StringIO.new [event, event, event].map(&:encode).join
    buffer.stub(:drain).and_yield(io)
  end

  subject do
    described_class.new(buffer)
  end

  it { should be_a(FluQ::Feed::Base) }
  its(:to_a) { should == [event, event, event] }

  it 'should log invalid inputs' do
    io = StringIO.new [event.encode, "ABCD", event.encode].join
    buffer.stub(:drain).and_yield(io)
    subject.logger.should_receive(:warn).at_least(:once)
    subject.to_a.should == [event, event]
  end

end
