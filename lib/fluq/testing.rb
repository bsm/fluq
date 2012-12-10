require 'fluq'

module FluQ::Testing
  extend self

  def wait_until(opts = {}, &block)
    tick = opts[:tick] || 0.01
    max  = opts[:max]  || (tick * 50)
    Timeout.timeout(max) { sleep(tick) until block.call }
  rescue Timeout::Error
  end
end

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
