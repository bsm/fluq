class FluQ::Format::Msgpack < FluQ::Format::Base

  # @see FluQ::Format::Base.to_event
  def self.to_event(raw)
    case raw
    when Hash
      FluQ::Event.new(raw)
    else
      logger.warn "buffer contained invalid event #{raw.inspect}"
      nil
    end
  end

  # Msgpack initializer
  # @see FluQ::Format::Base#initialize
  def initialize(*)
    super
    @buffer = MessagePack::Unpacker.new
  end

  protected

    # @see FluQ::Format::Base#parse_each
    def parse_each(chunk, &block)
      @buffer.feed_each(chunk, &block)
    end

end if defined?(MessagePack)
