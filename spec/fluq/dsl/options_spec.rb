require 'spec_helper'

describe Fluq::Dsl::Options do

  it 'should store options' do
    subject.val 42
    subject[:val].should == 42
  end

end
