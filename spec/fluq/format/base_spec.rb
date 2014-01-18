require 'spec_helper'

describe FluQ::Format::Base do

  it "should parse" do
    subject.parse("ANYTHING").should == []
  end

end
