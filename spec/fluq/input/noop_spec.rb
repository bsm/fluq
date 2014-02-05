require 'spec_helper'

describe FluQ::Input::Noop do

  subject { described_class.new "my-feed", [FluQ::Handler::Test] }
  it { should be_a(FluQ::Input::Base) }
  its(:wrapped_object) { should be_instance_of(described_class) }

  its(:name)    { should == "noop" }
  its(:description) { should == "noop" }

end
