require 'spec_helper'

describe FluQ::Buffer::Base do

  let(:handler) { FluQ::Handler::TestBuffered.new reactor, flush_rate: 2, buffer: 'memory' }
  let(:event)   { FluQ::Event.new("t", Time.now.to_i, {}) }
  subject       { handler.buffer }

  it_behaves_like "a buffer"
  it               { should be_a(described_class) }
  it               { should be_a(FluQ::Mixins::Loggable) }
  its(:flusher)    { should be_instance_of(Timers::Timer) }
  its(:interval)   { should be(60) }
  its(:rate)       { should be(2) }
  its(:handler)    { should be(handler) }

  it 'should limit rate' do
    FluQ::Handler::TestBuffered.new(reactor, flush_rate: 200_000).send(:buffer).send(:rate).should == 100_000
  end

  it 'should flush when rate is reached' do
    lambda {
      subject.concat [event]
    }.should_not change { handler.flushed }

    original = subject.send(:flusher).time
    sleep(0.01)
    lambda {
      subject.concat [event]
    }.should change { handler.flushed.size }.by(1)
    subject.send(:flusher).time.should > original # Should reset time too
  end

  it 'should flush when interval reached' do
    subject.concat [event]
    lambda {
      subject.send(:flusher).fire
    }.should change { handler.flushed.size }.by(1)
  end

  describe "flushing" do

    it 'should clear flushed events' do
      subject.concat [event]
      lambda { subject.flush }.should change(subject, :size).to(0)
    end

    it 'should keep events if flush fails' do
      subject.concat [FluQ::Event.new("error.flush", Time.now.to_i, {})]
      lambda { subject.flush }.should_not change(subject, :size).from(1)
    end

  end
end
