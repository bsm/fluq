class FluQ::Feed::Tsv < FluQ::Feed::Base

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
      tag, timestamp, json = line.split("\t")

      case hash = Oj.load(json)
      when Hash
        FluQ::Event.new tag, timestamp, hash
      else
        logger.warn "buffer contained invalid event #{[tag, timestamp, hash].inspect}"
        nil
      end
    rescue Oj::ParseError, ArgumentError
      logger.warn "buffer contained invalid line #{line.inspect}"
      nil
    end

end