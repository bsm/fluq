require 'spec_helper'

describe FluQ::Reactor do

  its(:handlers)   { should == [] }
  its(:inputs)     { should == [] }
  its(:scheduler)  { should be_instance_of(FluQ::Scheduler) }

  def events(*tags)
    tags.map do |tag|
      FluQ::Event.new(tag, 1313131313, {})
    end
  end

  it "should listen to inputs" do
    with_reactor do |subject|
      subject.listen(FluQ::Input::Socket, bind: "tcp://127.0.0.1:7654")
      subject.should have(1).inputs
    end
  end

  it "should register handlers" do
    h1 = subject.register(FluQ::Handler::Test)
    subject.should have(1).handlers

    h2 = subject.register(FluQ::Handler::Test, name: "specific")
    subject.should have(2).handlers
  end

  it "should prevent duplicates" do
    subject.register(FluQ::Handler::Test)
    lambda {
      subject.register(FluQ::Handler::Test)
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
    h1 = subject.register(FluQ::Handler::Test)
    10.times { subject.process(events("ok.now")) }
    subject.process(events("error.event"))
    10.times { subject.process(events("ok.now")) }
    FluQ::Testing.wait_until { h1.events.size > 19 }
    h1.should have(20).events
  end


end