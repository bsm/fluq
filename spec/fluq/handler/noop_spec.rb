require 'spec_helper'

describe FluQ::Handler::Noop do

  subject { described_class.new }

  it 'should handle events' do
    subject.on_events []
  end

end
