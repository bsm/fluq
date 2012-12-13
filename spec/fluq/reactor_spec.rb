require 'spec_helper'

describe FluQ::Reactor do
  subject { reactor }

  its(:handlers) { should == {} }
  its(:inputs)   { should be_a(Celluloid) }

  it "should listen to inputs" do
    server = subject.listen(FluQ::Input::Socket, bind: "tcp://127.0.0.1:7654")
    subject.inputs.should have(1).actors
    server.terminate
  end

  it "should register handlers" do
    h1 = subject.register(FluQ::Handler::Buffered)
    subject.handlers.should == { "buffered-M4na42" => h1 }

    h2 = subject.register(FluQ::Handler::Buffered, name: "specific")
    subject.handlers.should == { "buffered-M4na42" => h1, "specific" => h2 }
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
    subject.process("tag", 1313131313, {}).should be(true)

    FluQ::Testing.wait_until { h1.events.size > 0 }
    h1.events.should == [["tag", 1313131313, {}]]
    h2.events.should == []
  end

  it "should skip not matching events" do
    h1 = subject.register FluQ::Handler::Test, pattern: "NONE"
    FluQ::Testing.wait_until { false }
    h1.events.should == []
  end

end