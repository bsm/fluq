require 'spec_helper'

describe FluQ::Reactor do

  its(:handlers)    { should == [] }
  its(:inputs)      { should == [] }
  before            { FluQ::Testing.exceptions.clear }

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
    h1.events.should == [["tag", 1313131313, {}]]
    h2.events.should == []
  end

  it "should skip not matching events" do
    h1 = subject.register(FluQ::Handler::Test, pattern: "some*")
    subject.process(events("some.tag", "other.tag", "something.else")).should be(true)
    h1.events.should == [["some.tag", 1313131313, {}], ["something.else", 1313131313, {}]]
  end

  it "should recover crashed handlers gracefully" do
    h1 = subject.register(FluQ::Handler::Test)
    10.times { subject.process(events("ok.now")) }
    subject.process(events("error.event"))
    10.times { subject.process(events("ok.now")) }
    h1.should have(20).events
    FluQ::Testing.should have(1).exceptions
    FluQ::Testing.exceptions.last.should be_instance_of(RuntimeError)
  end

  it "should recover timeouts" do
    h1 = subject.register(FluQ::Handler::Test, timeout: 0.001)
    h1.events.should_receive(:concat).and_return {|*| sleep(0.01) }
    subject.process [FluQ::Event.new("ok.event", Time.now.to_i, "sleep" => 0.05)]
    FluQ::Testing.should have(1).exceptions
    FluQ::Testing.exceptions.last.should be_instance_of(Timeout::Error)
  end

end
