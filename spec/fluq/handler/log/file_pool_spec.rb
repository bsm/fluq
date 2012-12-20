require 'spec_helper'

describe FluQ::Handler::Log::FilePool do
  subject { described_class.new }

  before do
    FileUtils.rm_rf(FluQ.root.join('../scenario/tmp/file1.txt'))
  end

  it 'should open files in append mode by default' do
    file = subject.get(FluQ.root.join('../scenario/tmp/file1.txt'))
    file.write('A')
    file.write('BC')
    file.flush
    FluQ.root.join('../scenario/tmp/file1.txt').read.should == 'ABC'
  end

  it 'should cache file handles' do
    path = FluQ.root.join('../scenario/tmp/file1.txt')
    file = subject.get(path)
    subject.get(path).object_id.should == file.object_id
  end

  it 'should close stale handles' do
    subject = described_class.new(ttl: -1)
    file = subject.get(FluQ.root.join('../scenario/tmp/file1.txt'))
    subject.close_stale
    file.closed?.should be(true)
  end

  it 'should close all handles on finalize' do
    file = subject.get(FluQ.root.join('../scenario/tmp/file1.txt'))
    subject.finalize
    file.closed?.should be(true)
  end

end
