require 'spec_helper'

describe FluQ::Scheduler do

  it { should be_a(::Timers) }
  its(:runner) { should be_instance_of(Thread) }

  it 'should schedule events' do
    ran = false
    subject.after(0.01) { ran = true }
    lambda { sleep(0.02) }.should change { ran }.to(true)
  end

  it 'should log exceptions' do
    logged = []
    subject.logger.exception_handler {|e| logged << e }
    subject.after(0.01) { raise 'boom' }
    lambda { sleep(0.02) }.should change { logged.map(&:inspect) }.to(["#<RuntimeError: boom>"])
  end

end
