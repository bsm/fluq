require 'fluq'

class FluQ::Handler::Test < FluQ::Handler::Base
  attr_reader :events

  def initialize(*)
    super
    @events = []
  end

  def on_event(event)
    @events << event
  end
end

class FluQ::Handler::TestBuffered < FluQ::Handler::Buffered
  attr_reader :events, :flushed

  def initialize(*)
    super
    @events  = []
    @flushed = []
  end

  def on_event(event)
    @events << event
  end

  def on_flush(events)
    @flushed << events
  end
end
