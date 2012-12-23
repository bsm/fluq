require 'spec_helper'

describe FluQ::Scheduler do

  let(:runner) { subject.send(:runner) }

  it { should be_a(::Timers) }
  its(:runner) { should be_nil }

  it 'should schedule events' do
    ran = false
    subject.after(0.01) { ran = true }
    lambda { sleep(0.02) }.should change { ran }.to(true)

    runner.should be_instance_of(Thread)
    runner.should_not be_alive
  end

  it 'should launch runner when timers are active' do
    lambda {
      subject.every(1) { :ok }
    }.should change {
      subject.send(:runner)
    }.from(nil).to(instance_of(Thread))
  end

  it 'should shutdown runner when nothing scheduled' do
    t1 = subject.every(1) { 1 }
    t2 = subject.every(1) { 2 }
    runner.should be_alive

    t2.cancel
    sleep(0.01)
    runner.should be_alive

    t1.cancel
    sleep(0.01)
    runner.should_not be_alive
  end

end