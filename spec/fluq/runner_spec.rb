require 'spec_helper'

describe FluQ::Runner do

  its(:feeds)   { should == [] }
  its(:inspect) { should == "#<FluQ::Runner feeds: []>" }

  it "should register feeds" do
    subject.feed("my-feed")
    subject.should have(1).feeds

    subject.feed("other-feed")
    subject.should have(2).feeds
  end

end
