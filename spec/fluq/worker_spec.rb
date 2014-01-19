require 'spec_helper'

describe FluQ::Worker do

  class BadHandler < FluQ::Handler::Base
    def filter(events)
      events.reject! {|_| false }
    end
  end

  let(:filtered) { event("filter" => true) }

  def event(data = {})
    FluQ::Event.new(data)
  end

  def events(num)
    (0...num).map { event }
  end

  subject do
    described_class.new "src", []
  end

  its(:wrapped_object)  { should be_instance_of(described_class) }
  its(:prefix)          { should == "src" }
  its(:handlers)        { should have(:no).items }

  it "should accept handlers" do
    h1 = subject.add(FluQ::Handler::Test)
    subject.should have(1).handlers
  end

  it "should process events" do
    subject.add(FluQ::Handler::Test)
    subject.add(FluQ::Handler::Test)
    subject.process(events(1)).should be(true)
    subject.handlers[0].should have(1).events
    subject.handlers[1].should have(1).events
  end

  it "should prevent handlers from behaving badly" do
    h1 = subject.add(BadHandler)
    -> {
      subject.process(events(1))
    }.should raise_error(RuntimeError, /frozen/)
  end

  it "should skip filtered events" do
    h1 = subject.add(FluQ::Handler::Test)
    subject.process(events(2) + [filtered] + events(3)).should be(true)
    h1.should have(5).events
  end

  it "should apply timeouts" do
    h1 = subject.add(FluQ::Handler::Test, timeout: 0.001)
    h1.events.stub(:concat).and_return {|*| sleep(0.1) }
    -> {
      subject.process events(1)
    }.should raise_error(Timeout::Error)
  end

  it "should propagate handler crashes" do
    h1 = subject.add(FluQ::Handler::Test)
    h1.events.stub(:concat).and_raise("BOOM!")
    -> {
      subject.process events(1)
    }.should raise_error(RuntimeError)
    subject.inspect.should include("(FluQ::Worker) dead")
  end

  it "should execute handler timers" do
    x = 0
    h = subject.add(FluQ::Handler::Test)
    h.timers.every(0.01) { x += 1 }
    20.times { break if x > 0; sleep(0.01) }
    x.should > 0
  end

  it "should propagate handler timer crashes" do
    h1 = subject.add(FluQ::Handler::Test)
    h1.timers.every(0.01) { raise "BOOM!" }
    20.times { break if subject.inspect.include?("dead"); sleep(0.01) }
    subject.inspect.should include("(FluQ::Worker) dead")
  end

end
