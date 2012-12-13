require 'spec_helper'

describe FluQ::Buffer::Base do

  let(:handler) { FluQ::Handler::TestBuffered.new flush_rate: 2, buffer: 'memory' }
  subject       { handler.send(:buffer) }

  it_behaves_like "a buffer"
  it               { should be_a(described_class) }
  it               { should be_a(FluQ::Mixins::Loggable) }
  its(:handler)    { should be(handler) }
  its(:timer)      { should be_instance_of(Timers::Timer) }
  its(:interval)   { should be(60) }
  its(:rate)       { should be(2) }

  it 'should limit rate' do
    FluQ::Handler::TestBuffered.new(flush_rate: 200_000).send(:buffer).send(:rate).should == 100_000
  end

  it 'should flush when rate is reached' do
    lambda {
      subject.push FluQ::Event.new("t", Time.now.to_i, {})
    }.should_not change { handler.flushed }

    original = subject.send(:timer).time
    sleep(0.01)
    lambda {
      subject.push FluQ::Event.new("t", Time.now.to_i, {})
    }.should change { handler.flushed.size }.by(1)
    subject.send(:timer).time.should > original # Should reset time too
  end

  it 'should flush when interval reached' do
    subject.push FluQ::Event.new("t", Time.now.to_i, {})
    lambda {
      subject.send(:timer).fire
    }.should change { handler.flushed.size }.by(1)
  end

  it 'should not flush without events' do
    lambda {
      subject.flush
    }.should_not change { handler.flushed }
  end

  describe "flushing" do

    it 'should clear flushed events' do
      subject.push FluQ::Event.new("t", Time.now.to_i, {})
      lambda { subject.flush }.should change(subject, :size).to(0)
    end

    it 'should keep events if flush fails' do
      subject.push FluQ::Event.new("t", Time.now.to_i, {})
      handler.should_receive(:on_flush).and_raise(FluQ::Handler::Buffered::FlushError)
      lambda { subject.flush }.should_not change(subject, :size).from(1)
    end

  end
end
