require 'spec_helper'

describe FluQ::Handler::Noop do

  it 'should handle events' do
    subject.on_events []
  end

end
