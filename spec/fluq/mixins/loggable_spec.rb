require 'spec_helper'

describe FluQ::Mixins::Loggable do

  let(:worker) { double FluQ::Worker }
  subject      { FluQ::Handler::Base.new worker }

  it { should be_a(described_class) }
  its(:logger) { should be(FluQ.logger) }

end
