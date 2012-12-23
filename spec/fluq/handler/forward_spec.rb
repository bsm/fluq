require 'spec_helper'

describe FluQ::Handler::Forward do

  let(:event) do
    FluQ::Event.new("tag", 1313131313, { "a" => "1" })
  end

  subject do
    described_class.new reactor.current_actor, to: ["tcp://127.0.0.1:26712", "tcp://127.0.0.1:26713"]
  end

  it { should be_a(FluQ::Handler::Buffered) }
  its(:config) { should == { pattern: "*", flush_interval: 60, flush_rate: 0, buffer: "memory", buffer_options: {}, to: ["tcp://127.0.0.1:26712", "tcp://127.0.0.1:26713"] } }

  it 'requires URLs to be configured' do
    lambda { described_class.new }.should raise_error(ArgumentError)
  end

  it 'should forward messages' do
    messages = MockTCPServer.listen(26712, 26713) do
      subject.on_flush([event, event])
    end
    messages.should == {26712 => [event.to_a] * 2, 26713=>[]}
  end

  it 'should round-robin backends' do
    messages = MockTCPServer.listen(26712, 26713) do
      subject.on_flush([event])
      subject.on_flush([event, event])
    end
    messages.should == {26712 => [event.to_a] * 2, 26713=>[event.to_a] }
  end

  it 'should handle failures' do
    messages = MockTCPServer.listen(26712) do |servers|
      subject.on_flush([event])
      subject.on_flush([event, event])
    end
    messages.should == {26712 => [event.to_a] * 3}
  end

  it 'should throw errors when all backends fail' do
    lambda { subject.on_flush([event]) }.should raise_error(FluQ::Handler::Buffered::FlushError)
  end

end