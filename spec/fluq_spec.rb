require 'spec_helper'

describe Fluq do

  its(:env)  { should == "test" }
  its(:root) { should be_instance_of(Pathname) }
  its(:logger) { should be_instance_of(Logger) }
  its(:logger) { subject.level.should == Logger::DEBUG }

end