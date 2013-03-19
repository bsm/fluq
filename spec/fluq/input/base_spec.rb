require 'spec_helper'

describe FluQ::Input::Base do

  subject do
    described_class.new(reactor)
  end

  it { should be_a(FluQ::Mixins::Loggable) }
  its(:reactor) { should be(reactor) }
  its(:config)  { should == {buffer: "file", buffer_options: {}} }
  its(:name)    { should == "base" }
  its(:buffer_klass) { should == FluQ::Buffer::File }

end
