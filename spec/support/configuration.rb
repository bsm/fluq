class TestHandler < FluQ::Handler::Base
  @@events = Hash.new {|h, k| h[k] = [] }

  def self.events
    @@events
  end

  def on_event(event)
    @@events[name] << event
  end
end

class TestBufferedHandler < FluQ::Handler::Buffered
  @@events  = Hash.new {|h, k| h[k] = [] }
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

Celluloid::SupervisionGroup.class_eval do

  def __reset__
    finalize
    sleep(0.001) while actors.any?
    @members.clear
  end

end

RSpec.configure do |c|
  c.before do
    TestHandler.events.clear
    TestBufferedHandler.events.clear
    TestBufferedHandler.flushed.clear
  end
  c.after do
    # FluQ.reactor.inputs.finalize
    FluQ.reactor.inputs.__reset__
    FluQ.reactor.handlers.clear
  end
end

