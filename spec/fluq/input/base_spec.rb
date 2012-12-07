require 'spec_helper'

describe FluQ::Input::Base do

  it { should be_a(FluQ::Mixins::Loggable) }
  its(:config) { should == {} }

end
