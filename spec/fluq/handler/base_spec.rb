require 'spec_helper'

describe FluQ::Handler::Base do

  subject { described_class.new reactor }

  it { should respond_to(:on_events) }
  it { should be_a(FluQ::Mixins::Loggable) }
  its(:reactor) { should be(reactor) }
  its(:config)  { should == { pattern: "*" } }
  its(:pattern) { should == /^.*$/ }
  its(:name)    { should == "base-M4na42" }

  def events(*tags)
    tags.map {|tag| event(tag) }
  end

  def event(tag)
    FluQ::Event.new(tag, 1313131313, {})
  end

  it 'should have a type' do
    described_class.type.should == "base"
  end

  it 'can have custom names' do
    described_class.new(reactor, name: "visitors").name.should == "visitors"
  end

  it 'should match tags correctly' do
    subject = described_class.new(reactor, pattern: "visits.????.*")
    subject.match?(event("visits.site.1")).should be(true)
    subject.match?(event("visits.page.2")).should be(true)
    subject.match?(event("visits.other.1")).should be(false)
    subject.match?(event("visits.site")).should be(false)
    subject.match?(event("visits.site.")).should be(true)
    subject.match?(event("prefix.visits.site.1")).should be(false)
    subject.match?(event("visits.site.1.suffix")).should be(true)
  end

  it 'should select events' do
    stream = events("visits.site.1", "visits.page.2", "visits.other.1", "visits.site.2")
    described_class.new(reactor, pattern: "visits.????.*").select(stream).map(&:tag).should == [
      "visits.site.1", "visits.page.2", "visits.site.2"
    ]
  end

end