class FluQ::Feed::Tsv < FluQ::Feed::Base

  # @see FluQ::Feed::Base.to_event
  def self.to_event(raw)
    tag, timestamp, json = raw.split("\t")

    case hash = Oj.load(json)
    when Hash
      FluQ::Event.new tag, timestamp, hash
    else
      logger.warn "buffer contained invalid event #{hash.inspect}"
      nil
    end
  rescue Oj::ParseError, ArgumentError
    logger.warn "buffer contained invalid line #{raw.inspect}"
    nil
  end

  protected

    # @see [FluQ::Feed::Base] each_raw
    def each_raw
      buffer.drain do |io|
        while line = io.gets
          yield line
        end
      end
    end

end