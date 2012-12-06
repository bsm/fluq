class TestHandler < Fluq::Handler::Base
  @@events = Hash.new {|h, k| h[k] = [] }

  def self.events
    @@events
  end

  def on_event(event)
    @@events[name] << event
  end
end

class TestBufferedHandler < Fluq::Handler::Buffered
  @@events = Hash.new {|h, k| h[k] = [] }
  @@flushed = Hash.new {|h, k| h[k] = [] }

  def self.events
    @@events
  end

  def self.flushed
    @@flushed
  end

  def on_event(event)
    @@events[name] << event
  end

  def on_flush(events)
    @@flushed[name] << events
  end
end

RSpec.configure do |c|
  c.before do
    TestHandler.events.clear
    TestBufferedHandler.events.clear
    TestBufferedHandler.flushed.clear
  end
  c.after do
    Fluq.reactor.handlers.clear
  end
end

