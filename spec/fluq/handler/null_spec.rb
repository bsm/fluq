require 'spec_helper'

describe FluQ::Handler::Null do

  it 'should handle events' do
    subject.on_events []
  end

end
