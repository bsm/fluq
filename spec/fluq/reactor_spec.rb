require 'spec_helper'

describe FluQ::Reactor do

  its(:handlers) { should == [] }
  its(:inputs)   { should == [] }

  it "should listen to inputs" do
    subject.listen(FluQ::Input::Socket, bind: "tcp://127.0.0.1:7654")
    subject.should have(1).inputs
  end

  it "should register handlers" do
    h1 = subject.register(FluQ::Handler::Test)
    subject.should have(1).handlers

    h2 = subject.register(FluQ::Handler::Test, name: "specific")
    subject.should have(2).handlers
  end

  it "should prevent duplicates" do
    subject.register(FluQ::Handler::Test)
    -> {
      subject.register(FluQ::Handler::Test)
    }.should raise_error(ArgumentError)
  end

end
