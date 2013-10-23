require 'fluq'

module FluQ::Testing
  extend self
  EXCEPTION_TRACKER = ->ex { FluQ::Testing.exceptions.push(ex) }

  def wait_until(opts = {}, &block)
    tick = opts[:tick] || 0.01
    max  = opts[:max]  || (tick * 50)
    Timeout.timeout(max) { sleep(tick) until block.call }
  rescue Timeout::Error
  end

  def exceptions
    @exceptions ||= []
  end

  def track_exceptions!(logger = FluQ.logger)
    return if logger.exception_handlers.include?(EXCEPTION_TRACKER)
    logger.exception_handler(&EXCEPTION_TRACKER)
  end

end

class FluQ::Handler::Test < FluQ::Handler::Base
  attr_reader :events

  def initialize(*)
    super
    @events = []
  end

  def on_events(events)
    raise RuntimeError, "Test Failure!" if events.any? {|e| e.tag == "error.event" }
    @events.concat events
  end

end

