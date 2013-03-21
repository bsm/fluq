require 'spec_helper'

describe FluQ::Feed::Base do

  let(:buffer) { FluQ::Buffer::Base.new }

  subject do
    described_class.new(buffer)
  end

  it { should be_a(Enumerable) }
  its(:buffer)  { should be(buffer) }
  its(:to_a)    { should == [] }

end
