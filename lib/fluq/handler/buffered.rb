class FluQ::Handler::Buffered < FluQ::Handler::Base
  FlushError = Class.new(FluQ::Error)

  # @attr_reader [Celluloid::SupervisionGroup]
  attr_reader :supervisor

  # @see FluQ::Handler::Base#initialize
  def initialize(*)
    super
    @supervisor = FluQ::Buffer.const_get(config[:buffer].to_s.capitalize).supervise(self, config[:buffer_options] || {})
  end

  # @return [FluQ::Buffer] current buffer
  def buffer
    @supervisor.actors[0]
  end

  # @see FluQ::Handler::Base#on_events
  def on_events(events)
    buffer.concat(events)
  end

  # @abstract callback, called on each flush
  # @param [Array<Event>] events the events
  def on_flush(events)
    logger.debug { "#{self.class.name}#on_flush events: #{events.size}" }
  end

  protected

    # Configuration defaults
    def defaults
      super.merge flush_interval: 60, flush_rate: 0, buffer: 'memory', buffer_options: {}
    end

end