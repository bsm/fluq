class FluQ::Feed::Msgpack < FluQ::Feed::Base

  # @see FluQ::Feed::Base.to_event
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
  # @see FluQ::Feed::Base#initialize
  def initialize(*)
    super
    @buffer = MessagePack::Unpacker.new
  end

  protected

    # @see FluQ::Feed::Base#feed
    def feed(data, &block)
      @buffer.feed_each(data, &block)
    end

end
