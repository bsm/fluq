require 'spec_helper'

describe Fluq::Buffer::Memory do

  let(:handler) { Fluq::Handler::Buffered.new flush_rate: 2 }
  subject       { handler.send(:buffer) }

  it_behaves_like "a buffer"
  it { should be_a(Fluq::Buffer::Base) }
  its(:events)     { should == [] }

end