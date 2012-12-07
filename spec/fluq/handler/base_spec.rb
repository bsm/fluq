require 'spec_helper'

describe FluQ::Handler::Base do

  it { should respond_to(:on_event) }
  it { should be_a(FluQ::Mixins::Loggable) }
  its(:config) { should == { pattern: "*" } }
  its(:name)   { should == "base-M4na42" }

  it 'should have a type' do
    described_class.type.should == "base"
  end

  it 'can have custom names' do
    described_class.new(name: "visitors").name.should == "visitors"
  end

  it 'should match tags correctly' do
    subject = described_class.new(pattern: "visits.????.*")
    subject.match?("visits.site.1").should be(true)
    subject.match?("visits.page.2").should be(true)
    subject.match?("visits.other.1").should be(false)
    subject.match?("visits.site").should be(false)
    subject.match?("visits.site.").should be(true)
    subject.match?("prefix.visits.site.1").should be(false)
    subject.match?("visits.site.1.suffix").should be(true)
  end

end
