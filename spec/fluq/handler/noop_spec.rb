require 'spec_helper'

describe FluQ::Handler::Noop do

  let(:worker) { double FluQ::Worker }
  subject      { described_class.new worker }

  it 'should handle events' do
    subject.on_events []
  end

end
