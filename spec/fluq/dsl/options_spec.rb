require 'spec_helper'

describe Fluq::DSL::Options do

  it 'should store options' do
    subject.val 42
    subject[:val].should == 42
  end

end
