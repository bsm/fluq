require 'spec_helper'

describe FluQ::Mixins::Loggable do

  subject { FluQ::Handler::Base.new }

  it { should be_a(described_class) }
  its(:logger) { should be(FluQ.logger) }

end
