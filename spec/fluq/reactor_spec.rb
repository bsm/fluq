require 'spec_helper'

describe FluQ::Reactor do

  class FluQ::Handler::TestFailing < FluQ::Handler::Test

    def on_events(events)
      raise RuntimeError, "Failure!" if events.any? {|e| e.tag == "fail.now" }
      super
    end

  end

  subject { reactor }

  its(:handlers)   { should == [] }
  its(:inputs)     { should be_a(Celluloid) }
  its(:scheduler)  { should be_instance_of(FluQ::Scheduler) }

  def events(*tags)
    tags.map do |tag|
      FluQ::Event.new(tag, 1313131313, {})
    end
  end

  it "should listen to inputs" do
    server = subject.listen(FluQ::Input::Socket, bind: "tcp://127.0.0.1:7654")
    subject.should have(1).inputs
    server.terminate
  end

  it "should register handlers" do
    h1 = subject.register(FluQ::Handler::Buffered)
    subject.should have(1).handlers

    h2 = subject.register(FluQ::Handler::Buffered, name: "specific")
    subject.should have(2).handlers
  end

  it "should prevent duplicates" do
    subject.register(FluQ::Handler::Buffered)
    lambda {
      subject.register(FluQ::Handler::Buffered)
    }.should raise_error(ArgumentError)
  end

  it "should process events" do
    h1 = subject.register(FluQ::Handler::Test)
    h2 = subject.register(FluQ::Handler::Test, pattern: "NONE")
    subject.process(events("tag")).should be(true)

    FluQ::Testing.wait_until { h1.events.size > 0 }
    h1.events.should == [["tag", 1313131313, {}]]
    h2.events.should == []
  end

  it "should skip not matching events" do
    h1 = subject.register(FluQ::Handler::Test, pattern: "some*")
    subject.process(events("some.tag", "other.tag", "something.else")).should be(true)
    FluQ::Testing.wait_until { h1.events.size > 1 }
    h1.events.should == [["some.tag", 1313131313, {}], ["something.else", 1313131313, {}]]
  end

  it "should recover crashed handlers gracefully" do
    h1 = subject.register(FluQ::Handler::TestFailing)
    10.times { subject.process(events("ok.now")) }
    subject.process(events("fail.now"))
    10.times { subject.process(events("ok.now")) }
    h1.should have(20).events
  end


end