require 'spec_helper'

describe FluQ::Buffer::Base do

  let(:handler) { TestBufferedHandler.new flush_rate: 2, buffer: 'memory' }
  subject       { handler.send(:buffer) }

  it_behaves_like "a buffer"
  it               { should be_a(described_class) }
  it               { should be_a(FluQ::Mixins::Loggable) }
  its(:handler)    { should be(handler) }
  its(:timers)     { should be_instance_of(Timers) }
  its(:interval)   { should be(60) }
  its(:rate)       { should be(2) }

  it 'should limit rate' do
    TestBufferedHandler.new(flush_rate: 20_000).send(:buffer).send(:rate).should == 10_000
  end

  it 'should flush when rate is reached' do
    lambda {
      subject.push FluQ::Event.new("t", Time.now.to_i, {})
    }.should_not change { TestBufferedHandler.flushed[handler.name] }
    lambda {
      subject.push FluQ::Event.new("t", Time.now.to_i, {})
    }.should change { TestBufferedHandler.flushed[handler.name].size }.by(1)
  end

  it 'should flush when interval reached' do
    lambda {
      subject.send(:timers).each(&:fire)
    }.should change { TestBufferedHandler.flushed[handler.name].size }.by(1)
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