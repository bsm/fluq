class TestHandler < Fluq::Handler::Base
  @@events = {}

  def self.events
    @@events
  end

  def on_event(event)
    @@events[name] ||= []
    @@events[name] << event
  end
end

RSpec.configure do |c|
  c.before do
    TestHandler.events.clear
  end
  c.after do
    Fluq.reactor.handlers.clear
  end
end

