require 'spec_helper'

describe FluQ::Feed::Tsv do

  let(:data) { %(1313131313\t{"a":"b"}\n1313131313\t{"a":"b"}\n1313131313\t{"a":"b"}\n) }

  it { should be_a(FluQ::Feed::Lines) }

  it 'should parse' do
    events = subject.parse(data)
    events.should have(3).items
    events.first.should == FluQ::Event.new({"a" => "b"}, 1313131313)
  end

  it 'should log invalid inputs' do
    subject.logger.should_receive(:warn).once
    events = subject.parse data + %(NOTTSV\n1313131313\t{"a":"b"}\n\n)
    events.should have(4).items
  end

end
