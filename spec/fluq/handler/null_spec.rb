require 'spec_helper'

describe FluQ::Handler::Null do

  subject { described_class.new reactor.current_actor }

  it 'should handle events' do
    subject.on_events []
  end

end
