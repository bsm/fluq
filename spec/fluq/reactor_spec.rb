require 'spec_helper'

describe FluQ::Reactor do

  let(:reactor) { described_class.new }
  subject { reactor }

  def wait_for_workers!
    sleep(0.001) while reactor.workers.tasks.any? {|t| [:running, :sleeping].include?(t.status) }
  end

  its(:handlers) { should == {} }
  its(:workers)  { should be_a(Celluloid) }
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
    h1 = subject.register(TestHandler)
    h2 = subject.register(TestHandler, pattern: "NONE")
    subject.process("tag", 1313131313, {}).should be(true)

    wait_for_workers!
    TestHandler.events.should == { h1.name => [["tag", 1313131313, {}]] }
  end

  it "should skip not matching events" do
    h1 = subject.register FluQ::Handler::Base, pattern: "NONE"
    wait_for_workers!
    TestHandler.events.should == {}
  end

end