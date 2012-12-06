require 'spec_helper'

describe FluQ::Buffer::Memory do

  let(:handler) { FluQ::Handler::Buffered.new flush_rate: 2 }
  subject       { handler.send(:buffer) }

  it_behaves_like "a buffer"
  it { should be_a(FluQ::Buffer::Base) }
  its(:store)   { should == [] }

end