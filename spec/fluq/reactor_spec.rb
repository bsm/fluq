require 'spec_helper'

describe FluQ::Reactor do
  subject { reactor }

  it              { should be_a(Celluloid) }
  its(:handlers)  { should == {} }
  its(:actors)    { should == [] }
  its(:scheduler) { should be_instance_of(FluQ::Scheduler) }

  def events(*tags)
    tags.map do |tag|
      FluQ::Event.new(tag, 1313131313, {})
    end
  end

  it "should listen to inputs" do
    server = subject.listen(FluQ::Input::Socket, bind: "tcp://127.0.0.1:7654")
    subject.should have(1).actors
    server.terminate
  end

  it "should register handlers" do
    h1 = subject.register(FluQ::Handler::Buffered)
    subject.handlers.should == { "buffered-M4na42" => h1 }
    subject.should have(1).actors

    h2 = subject.register(FluQ::Handler::Buffered, name: "specific")
    subject.handlers.should == { "buffered-M4na42" => h1, "specific" => h2 }
    subject.should have(2).actors
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
    h1 = subject.register FluQ::Handler::Test, pattern: "some*"
    subject.process(events("some.tag", "other.tag", "something.else")).should be(true)
    FluQ::Testing.wait_until { h1.events.size > 1 }
    h1.events.should == [["some.tag", 1313131313, {}], ["something.else", 1313131313, {}]
    ]
  end

end