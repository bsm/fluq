require 'spec_helper'

describe FluQ::Buffer::Base do

  it { should be_a(Enumerable) }
  its(:config)  { should == {max_size: 268435456} }
  its(:to_a)    { should == [] }
  its(:size)    { should be(0) }
  it { should respond_to(:write) }
  it { should respond_to(:close) }
  it { should_not be_full }

  describe 'when size exeeds limit' do
    before { subject.stub size: 268435457 }
    it { should be_full }
  end

end
