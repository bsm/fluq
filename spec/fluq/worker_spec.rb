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
    described_class.new "src", [[FluQ::Handler::Test]]
  end

  its(:wrapped_object)  { should be_instance_of(described_class) }
  its(:prefix)          { should == "src" }
  its(:handlers)        { should have(1).items }
  its("handlers.first") { should be_instance_of(FluQ::Handler::Test) }

  it "should accept handlers" do
    h1 = subject.add(FluQ::Handler::Test)
    subject.should have(2).handlers
  end

  it "should process events" do
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
    subject.process(events(2) + [filtered] + events(3)).should be(true)
    subject.handlers[0].should have(5).events
  end

  it "should apply timeouts" do
    h1 = subject.add(FluQ::Handler::Test, timeout: 0.001)
    h1.events.should_receive(:concat).and_return {|*| sleep(0.01) }
    -> {
      subject.process events(1)
    }.should raise_error(Timeout::Error)
  end

end
