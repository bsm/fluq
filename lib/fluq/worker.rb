class FluQ::Worker
  include Celluloid
  include FluQ::Mixins::Loggable

  attr_reader :prefix, :handlers

  # @param [Array<Class,Array>] handlers handler builders
  def initialize(prefix, handlers = [])
    @prefix   = prefix
    @handlers = handlers.map do |klass, *args|
      klass.new(*args)
    end
  end

  # @param [Array<FluQ::Event>] events to process
  def process(events)
    events.freeze # Freeze events, don't allow individual handlers to modify them
    handlers.each do |handler|
      on_events(handler, Time.now, events)
    end
    true
  end

  protected

    def on_events(handler, start, events)
      matching = handler.filter(events)
      ::Timeout.timeout handler.config[:timeout] do
        handler.on_events(matching)
        logger.info { "#{prefix}:#{handler.name} #{matching.size}/#{events.size} events in #{((Time.now - start) * 1000).round}ms" }
      end unless matching.empty?
    end

end
