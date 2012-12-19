require 'spec_helper'

describe FluQ::Event::Unpacker do

  let(:event) { FluQ::Event.new("some.tag", 1313131313) }
  let(:buffer) do
    path = FluQ.root.join("tmp/buffer")
    path.open("wb") do |f|
      f.write event.encode
      f.write FluQ::Event.new("other.tag", 1313131313).encode
      f.write FluQ::Event.new("final.tag", 1313131313).encode
    end
    path
  end

  subject { described_class.new(buffer.open("r")) }

  it { should be_a(Enumerable) }
  its(:to_a) { should have(3).items }
  its(:to_a) { should include(event) }

  it 'should iterate only once' do
    subject.to_a
    lambda { subject.to_a }.should raise_error(IOError, /closed stream/i)
  end

  it 'should deal with partial inputs' do
    buffer.open("ab") do |f|
      f.write MessagePack.pack(["partial"])
    end
    events = subject.to_a
    events.should have(4).items
    events.last.should be_instance_of(FluQ::Event)
    events.to_a.last.should == ["partial", 0, {}]
  end

  it 'should deal with wrong inputs' do
    buffer.open("ab") do |f|
      f.write MessagePack.pack("wrong")
    end
    events = subject.to_a
    events.should have(4).items
    events.last.should be_instance_of(FluQ::Event)
    events.last.should == ["wrong", 0, {}]
  end

end