class FluQ::Handler::Buffered < FluQ::Handler::Base
  FlushError = Class.new(FluQ::Error)

  # @return [FluQ::Buffer] current buffer
  attr_reader :buffer

  # @see FluQ::Handler::Base#initialize
  def initialize(*)
    super
    @buffer = FluQ::Buffer.const_get(config[:buffer].to_s.capitalize).new(self, config[:buffer_options] || {})
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