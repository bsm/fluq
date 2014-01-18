require 'spec_helper'

describe FluQ::DSL::Root do

  let(:runner) { FluQ::Runner.new }
  subject      { described_class.new FluQ.root.join('../scenario/config/test.rb') }

  its(:feeds)  { should have(2).items }
  its("feeds.first") { should be_instance_of(FluQ::DSL::Feed) }

  it 'should apply configuration' do
    subject.apply(runner)
    runner.should have(2).feeds

    feed = runner.feeds.first
    feed.should have(1).inputs
    feed.should have(1).handlers
  end

end
