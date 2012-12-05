require 'spec_helper'

describe Fluq::Buffer::Base do

  let(:handler) { Fluq::Handler::Buffered.new flush_rate: 2, buffer: 'memory' }
  subject       { handler.send(:buffer) }

  it_behaves_like "a buffer"
  it               { should be_a(described_class) }
  its(:handler)    { should be(handler) }
  its(:flushed_at) { should be_instance_of(Time) }
  its(:flusher)    { should be_instance_of(Thread) }
  its(:due?)       { should be(false) }
  its(:interval_due?) { should be(false) }
  its(:rate_due?)     { should be(false) }

  it 'should be due when rate is reached' do
    lambda { subject.push Fluq::Event.new("t", Time.now.to_i, {}) }.should_not change(subject, :due?)
    lambda { subject.push Fluq::Event.new("t", Time.now.to_i, {}) }.should change(subject, :due?).to(true)
  end

  it 'should be due when interval is reached' do
    lambda { subject.instance_variable_set(:@flushed_at, Time.now - 55) }.should_not change(subject, :due?)
    lambda { subject.instance_variable_set(:@flushed_at, Time.now - 65) }.should change(subject, :due?).to(true)
  end

  describe "flushing" do

    it 'should store flush time' do
      lambda { subject.flush }.should change(subject, :flushed_at)
    end

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