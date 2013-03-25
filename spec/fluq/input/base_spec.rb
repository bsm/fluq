require 'spec_helper'

describe FluQ::Input::Base do

  let(:event)    { FluQ::Event.new("some.tag", 1313131313, {}) }
  let!(:handler) { reactor.register FluQ::Handler::Test }
  subject        { described_class.new(reactor, feed: "json") }

  it { should be_a(FluQ::Mixins::Loggable) }
  its(:reactor) { should be(reactor) }
  its(:config)  { should == {feed: "json", buffer: "file", buffer_options: {}} }
  its(:name)    { should == "base" }
  its(:feed_klass) { should == FluQ::Feed::Json }
  its(:buffer_klass) { should == FluQ::Buffer::File }

  it 'should create new buffers' do
    (b1 = subject.new_buffer).should be_instance_of(FluQ::Buffer::File)
    (b2 = subject.new_buffer).should be_instance_of(FluQ::Buffer::File)
    b1.should_not be(b2)
  end

  it 'should flush buffers' do
    buf = subject.new_buffer
    buf.write [event, event].map(&:to_json).join("\n")
    subject.flush!(buf)
    handler.should have(2).events
  end

end
