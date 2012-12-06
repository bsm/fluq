require 'spec_helper'

describe Fluq::Handler::Base do

  it { should respond_to(:on_event) }
  its(:config) { should == { pattern: "*" } }
  its(:name)   { should == "a872495fc91d7aeb4ac6a529d601e65f" }

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