class FluQ::Feed::Msgpack < FluQ::Feed::Base

  # @see FluQ::Feed::Base.to_event
  def self.to_event(raw)
    raw = MessagePack.unpack(raw) if raw.is_a?(String)

    case raw
    when Hash
      FluQ::Event.new raw.delete("="), raw.delete("@"), raw
    else
      logger.warn "buffer contained invalid event #{raw.inspect}"
      nil
    end
  end

  protected

    # @see [FluQ::Feed::Base] each
    def each_raw(&block)
      buffer.drain do |io|
        pac = MessagePack::Unpacker.new(io)
        pac.each(&block)
      end
    rescue EOFError
    end

end