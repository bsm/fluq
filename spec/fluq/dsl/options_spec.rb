require 'spec_helper'

describe FluQ::DSL::Options do

  it 'should store value options' do
    subject = described_class.new { val 42 }
    subject.to_hash[:val].should == 42
  end

  it 'should store block options' do
    subject = described_class.new { val { 42 } }
    subject.to_hash[:val].().should == 42
  end

end
