require 'spec_helper'

describe Fluq::Buffer::Base do

  let(:handler) { TestBufferedHandler.new flush_rate: 2, buffer: 'memory' }
  subject       { handler.send(:buffer) }

  it_behaves_like "a buffer"
  it               { should be_a(described_class) }
  its(:handler)    { should be(handler) }
  its(:timers)     { should be_instance_of(Timers) }

  it 'should flush when rate is reached' do
    lambda {
      subject.push Fluq::Event.new("t", Time.now.to_i, {})
    }.should_not change { TestBufferedHandler.flushed[handler.name] }
    lambda {
      subject.push Fluq::Event.new("t", Time.now.to_i, {})
    }.should change { TestBufferedHandler.flushed[handler.name].size }.by(1)
  end

  it 'should flush when interval reached' do
    lambda {
      subject.send(:timers).each(&:fire)
    }.should change { TestBufferedHandler.flushed[handler.name].size }.by(1)
  end

  describe "flushing" do

    it 'should clear flushed events' do
      subject.push Fluq::Event.new("t", Time.now.to_i, {})
      lambda { subject.flush }.should change(subject, :size).to(0)
    end

    it 'should keep events if flush fails' do
      subject.push Fluq::Event.new("t", Time.now.to_i, {})
      handler.should_receive(:on_flush).and_raise(Fluq::Handler::Buffered::FlushError)
      lambda { subject.flush }.should_not change(subject, :size).from(1)
    end

  end
end