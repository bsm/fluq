require 'spec_helper'

describe FluQ::Input::Base do

  let!(:handler) { reactor.register FluQ::Handler::Test }
  let(:data)     { [{"a" => 1}, {"b" => 2}].map {|h| MessagePack.pack(h) }.join }
  subject        { described_class.new(reactor, feed: "msgpack") }
  let(:jinput)   { described_class.new(reactor, feed: "json") }

  it { should be_a(FluQ::Mixins::Loggable) }
  its(:wrapped_object) { should be_instance_of(described_class) }
  its(:worker)  { should be_instance_of(FluQ::Worker) }
  its(:config)  { should == {feed: "msgpack", feed_options: {}} }
  its(:name)    { should == "base" }
  its(:feed)    { should be_instance_of(FluQ::Feed::Msgpack) }

  it 'should process' do
    subject.process(data)
    handler.should have(2).events
  end

  it 'should handle partial messages' do
    m1, m2 = data + data[0..1], data[2..-1]
    subject.process(m1)
    handler.should have(2).events
    subject.process(m2)
    handler.should have(4).events

    m1, m2 = data[0..-3], data[-3..-1] + data
    subject.process(m1)
    handler.should have(5).events
    subject.process(m2)
    handler.should have(8).events

    m1, m2 = %({"a":1,"b":2}\n{"a":1,"b":2}\n{"a":1), %(,"b":2}\n{"a":1,"b":2}\n)
    jinput.process(m1)
    handler.should have(10).events
    jinput.process(m2)
    handler.should have(12).events

    m1, m2 = %({"a":1,"b":2}\n{"a":1,), %("b":2}\n{"a":1,"b":2}\n{"a":1,"b":2}\n)
    jinput.process(m1)
    handler.should have(13).events
    jinput.process(m2)
    handler.should have(16).events
  end

end
