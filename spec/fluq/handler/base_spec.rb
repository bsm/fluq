require 'spec_helper'

describe FluQ::Handler::Base do

  let(:event)  { FluQ::Event.new({}) }

  it { should respond_to(:on_events) }
  it { should be_a(FluQ::Mixins::Loggable) }
  its(:config)  { should == { timeout: 60 } }
  its(:name)    { should == "base" }

  it 'should have a type' do
    described_class.type.should == "base"
  end

  it 'can have custom names' do
    described_class.new(name: "visitors").name.should == "visitors"
  end

  it 'should not filter events by default' do
    subject.filter([event, event]).should have(2).items
  end

end
