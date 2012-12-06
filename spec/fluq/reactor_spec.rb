require 'spec_helper'

describe Fluq::Reactor do

  let(:reactor) { described_class.new }
  subject { reactor }

  def wait_for_workers!
    sleep(0.001) while reactor.workers.tasks.any? {|t| [:running, :sleeping].include?(t.status) }
  end

  its(:handlers) { should == {} }
  its(:workers)  { should be_a(Celluloid) }
  its(:inputs)  { should be_a(Celluloid) }
  its(:inputs)  { should have(:no).actors }

  it "should listen to inputs" do
    server = subject.listen(Fluq::Input::Socket, bind: "tcp://127.0.0.1:7654")
    subject.inputs.should have(1).actors
    server.terminate
  end

  it "should register handlers" do
    h1 = Fluq::Handler::Buffered.new
    h2 = Fluq::Handler::Buffered.new name: "specific"

    subject.register(h1)
    subject.handlers.should == { "8e35a58704914c320a48ce87a06218c8" => h1 }

    subject.register(h2)
    subject.handlers.should == { "8e35a58704914c320a48ce87a06218c8" => h1, "specific" => h2 }
  end

  it "should prevent duplicates" do
    subject.register(Fluq::Handler::Buffered.new)
    lambda {
      subject.register(Fluq::Handler::Buffered.new)
    }.should raise_error(ArgumentError)
  end

  it "should process events" do
    h1 = TestHandler.new
    h2 = TestHandler.new pattern: "NONE"
    subject.register(h1)
    subject.register(h2)
    subject.process("tag", 1313131313, {}).should be(true)

    wait_for_workers!
    TestHandler.events.should == { h1.name => [["tag", 1313131313, {}]] }
  end

  it "should skip not matching events" do
    h1 = Fluq::Handler::Base.new pattern: "NONE"
    subject.register(h1)
    wait_for_workers!
    TestHandler.events.should == {}
  end

end