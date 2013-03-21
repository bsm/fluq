class FluQ::Feed::Msgpack < FluQ::Feed::Base

  # @see [FluQ::Feed::Base] each
  def each
    buffer.drain do |io|
      pac = MessagePack::Unpacker.new(io)
      pac.each do |hash|
        event = to_event(hash)
        yield event if event
      end
    end
  rescue EOFError
  end

  private

    def to_event(hash)
      case hash
      when Hash
        FluQ::Event.new hash.delete("="), hash.delete("@"), hash
      else
        logger.warn "buffer contained invalid event #{hash.inspect}"
        nil
      end
    end

end