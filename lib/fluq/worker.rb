class FluQ::Worker
  include Celluloid
  include FluQ::Mixins::Loggable
  finalizer :finalize

  attr_reader :prefix, :handlers

  # @param [Array<Class,Array>] handlers handler builders
  def initialize(prefix, handlers = [])
    @prefix   = prefix
    @handlers = []
    @observer = observe

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
    handler = klass.new(*args)
    handlers.push handler
    handler
  end

  protected

    def finalize
      @observer.kill if @observer
    end

    def on_events(handler, start, events)
      matching = handler.filter(events)
      ::Timeout::timeout handler.config[:timeout] do
        handler.on_events(matching)
        logger.info { "#{prefix}:#{handler.name} #{matching.size}/#{events.size} events in #{((Time.now - start) * 1000).round}ms" }
      end unless matching.empty?
    end

  private

    def next_timers
      handlers.map do |h|
        h.timers unless h.timers.empty?
      end.compact.sort_by(&:wait_interval)[0]
    end

    def observe
      parent = Thread.current
      Thread.new do
        loop do
          begin
            timers = next_timers
            timers ? timers.wait : sleep(0.1)
          rescue => e
            parent.raise(e)
          end
        end
      end
    end

end
