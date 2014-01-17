require 'spec_helper'

describe FluQ::Feed::Base do

  it "should parse" do
    subject.parse("ANYTHING").should == []
  end

end
