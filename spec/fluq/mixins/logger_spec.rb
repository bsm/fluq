require 'spec_helper'

describe FluQ::Mixins::Logger do

  subject do
    logger = Logger.new("/dev/null")
    logger.extend described_class
    logger
  end

  its(:exception_handlers) { should == [] }

  it 'should register handlers' do
    subject.exception_handler {|*| }
    subject.should have(1).exception_handlers
  end

  it 'should apply handlers on crash' do
    str = ""
    subject.exception_handler {|ex| str << ex.message }
    subject.crash("error", StandardError.new("something"))
    str.should == "something"
  end

end