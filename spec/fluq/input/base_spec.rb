require 'spec_helper'

describe FluQ::Input::Base do

  subject        { described_class.new([FluQ::Handler::Test], format: "msgpack") }
  let(:subject2) { described_class.new([FluQ::Handler::Test], format: "json") }
  let(:handler)  { subject.worker.handlers.first }
  let(:handler2) { subject2.worker.handlers.first }
  let(:data)     { [{"a" => 1}, {"b" => 2}].map {|h| MessagePack.pack(h) }.join }

  it { should be_a(FluQ::Mixins::Loggable) }
  its(:wrapped_object) { should be_instance_of(described_class) }

  its(:worker)  { should be_instance_of(FluQ::Worker) }
  its(:config)  { should == {format: "msgpack", format_options: {}} }
  its(:name)    { should == "base" }
  its(:description) { should == "base" }
  its(:format)  { should be_instance_of(FluQ::Format::Msgpack) }

  it 'should process' do
    subject.process(data)
    handler.should have(2).events
  end

  it 'should maintain separate handler instances per input' do
    -> {
      subject.process data
    }.should change { handler.events.size }.by(2)

    -> {
      subject2.process %({"a":1,"b":2}\n{"a":1,"b":2}\n{"a":1,"b":2}\n)
    }.should_not change { handler.events.size }
    handler2.should have(3).events
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
    subject2.process(m1)
    handler2.should have(2).events
    subject2.process(m2)
    handler2.should have(4).events

    m1, m2 = %({"a":1,"b":2}\n{"a":1,), %("b":2}\n{"a":1,"b":2}\n{"a":1,"b":2}\n)
    subject2.process(m1)
    handler2.should have(5).events
    subject2.process(m2)
    handler2.should have(8).events
  end

end
