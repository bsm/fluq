require 'spec_helper'

describe FluQ::Feed do

  subject  { described_class.new "my-feed" }

  its(:name)     { should == "my-feed" }
  its(:handlers) { should == [] }
  its(:inputs)   { should == [] }

  it "should listen to inputs" do
    subject.listen(FluQ::Input::Socket, bind: "tcp://127.0.0.1:7654")
    subject.should have(1).inputs
  end

  it "should register handlers" do
    h1 = subject.register(FluQ::Handler::Test)
    subject.should have(1).handlers

    h2 = subject.register(FluQ::Handler::Test)
    subject.should have(2).handlers
  end

end
