class FluQ::Feed::Json < FluQ::Feed::Base

  # @see [FluQ::Feed::Base] each
  def each
    buffer.drain do |io|
      while line = io.gets
        event = to_event(line)
        yield event if event
      end
    end
  end

  private

    def to_event(line)
      case hash = Oj.load(line)
      when Hash
        FluQ::Event.new hash.delete("="), hash.delete("@"), hash
      else
        logger.warn "buffer contained invalid event #{hash.inspect}"
        nil
      end
    rescue Oj::ParseError
      logger.warn "buffer contained invalid line #{line.inspect}"
      nil
    end

end