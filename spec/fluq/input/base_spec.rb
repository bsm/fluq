require 'spec_helper'

describe FluQ::Input::Base do

  subject do
    described_class.new(reactor)
  end

  it { should be_a(FluQ::Mixins::Loggable) }
  its(:reactor) { should be_instance_of(FluQ::Reactor) }
  its(:config) { should == {} }

end
