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

  def filter(events)
    events.reject {|e| e.key?("filter") }
  end

  def on_events(events)
    raise RuntimeError, "Test Failure!" if events.any? {|e| e.key?("error") }
    @events.concat events
  end

end

