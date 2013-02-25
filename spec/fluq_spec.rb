require 'spec_helper'

describe FluQ do

  its(:env)  { should == "test" }
  its(:root) { should be_instance_of(Pathname) }
  its(:logger) { should be_instance_of(Logger) }
  its("logger.level") { should == Logger::DEBUG }
  it { should respond_to(:logger=) }

end