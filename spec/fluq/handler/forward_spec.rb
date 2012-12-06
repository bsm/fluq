require 'spec_helper'

describe Fluq::Handler::Forward do

  let(:event) do
    Fluq::Event.new("tag", 1313131313, { "a" => "1" })
  end

  subject do
    described_class.new to: ["tcp://127.0.0.1:26712", "tcp://127.0.0.1:26713"]
  end

  it { should be_a(Fluq::Handler::Buffered) }
  its(:config) { should == { :pattern=>"*", :flush_interval=>60, :flush_rate=>0, :buffer=>"memory", :to=>["tcp://127.0.0.1:26712", "tcp://127.0.0.1:26713"] } }

  it 'requires URLs to be configured' do
    lambda { described_class.new }.should raise_error(ArgumentError)
  end

  it 'should forward messages' do
    messages = MockTCPServer.listen(26712, 26713) do
      subject.on_flush([event, event])
    end
    subject.urls.map(&:to_s).should == ["tcp://127.0.0.1:26713", "tcp://127.0.0.1:26712"]
    messages.should == {26712 => [event.to_a] * 2, 26713=>[]}
  end

  it 'should round-robin backends' do
    messages = MockTCPServer.listen(26712, 26713) do
      subject.on_flush([event])
      subject.on_flush([event, event])
    end
    subject.urls.map(&:to_s).should == ["tcp://127.0.0.1:26712", "tcp://127.0.0.1:26713"]
    messages.should == {26712 => [event.to_a], 26713=>[event.to_a] * 2}
  end

  it 'should handle failures' do
    messages = MockTCPServer.listen(26712) do |servers|
      subject.on_flush([event])
      subject.on_flush([event, event])
    end
    subject.should have(2).urls
    messages.should == {26712 => [event.to_a] * 3}
  end

  it 'should throw errors when all backends fail' do
    lambda { subject.on_flush([event]) }.should raise_error(Fluq::Handler::Buffered::FlushError)
    subject.should have(2).urls
  end

end