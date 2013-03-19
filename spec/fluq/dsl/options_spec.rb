require 'spec_helper'

describe FluQ::DSL::Options do

  it 'should store value options' do
    subject = described_class.new { val 42 }
    subject.to_hash.should == { val: 42 }
  end

  it 'should store block options' do
    subject = described_class.new { val { 42 } }
    subject.to_hash[:val].().should == 42
  end

  it 'should store boolean options' do
    subject = described_class.new { val }
    subject.to_hash.should == { val: true }
  end

  it 'should store values with sub-options' do
    described_class.new { val(42) { sub 21 } }.to_hash.should == { val: 42, val_options: { sub: 21 } }
  end

end
