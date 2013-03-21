require 'spec_helper'

describe FluQ::Buffer::Base do

  its(:config)  { should == {max_size: 268435456} }
  its(:size)    { should be(0) }
  its(:name)    { should == "base" }
  it { should respond_to(:write) }
  it { should respond_to(:close) }
  it { should_not be_full }

  it 'should drain' do
    subject.drain {|io| io.should be_instance_of(StringIO) }
  end

  describe 'when size exeeds limit' do
    before { subject.stub size: 268435457 }
    it { should be_full }
  end

end
