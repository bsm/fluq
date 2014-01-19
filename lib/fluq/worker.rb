class FluQ::Worker
  include Celluloid
  include FluQ::Mixins::Loggable

  attr_reader :prefix, :handlers

  # @param [Array<Class,Array>] handlers handler builders
  def initialize(prefix, handlers = [])
    @prefix   = prefix
    @handlers = []

    handlers.each do |klass, *args|
      add klass, *args
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

  # Adds a handler
  # @param [Class<FluQ::Handler::Base>] klass handler class
  # @param [multiple] args handler initialize arguments
  def add(klass, *args)
    handler = klass.new(current_actor, *args)
    handlers.push handler
    handler
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
