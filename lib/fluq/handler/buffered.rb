class FluQ::Handler::Buffered < FluQ::Handler::Base
  FlushError = Class.new(FluQ::Error)

  attr_reader :buffer

  # @see FluQ::Handler::Base#initialize
  def initialize(*)
    super
    @buffer = FluQ::Buffer.const_get(config[:buffer].to_s.capitalize).new(self)
  end

  # @see FluQ::Handler::Base#on_event
  def on_event(event)
    buffer.push event
  end

  # @abstract callback, called on each flush
  # @param [Array<Event>] events the events
  def on_flush(events)
  end

  protected

    # Configuration defaults
    def defaults
      super.merge flush_interval: 60, flush_rate: 0, buffer: 'memory'
    end

end