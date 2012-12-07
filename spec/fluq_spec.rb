require 'spec_helper'

describe FluQ do

  its(:env)  { should == "test" }
  its(:root) { should be_instance_of(Pathname) }
  its(:logger) { should be_instance_of(Logger) }
  its(:logger) { subject.level.should == Logger::DEBUG }
  its(:reactor) { should be_instance_of(FluQ::Reactor) }
  its(:timers) { should be_instance_of(Timers) }
  it { should respond_to(:logger=) }

end