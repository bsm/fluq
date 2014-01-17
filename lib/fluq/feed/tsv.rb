class FluQ::Feed::Tsv < FluQ::Feed::Lines

  # @see FluQ::Feed::Base.to_event
  def self.to_event(raw)
    timestamp, json = raw.split("\t")

    case hash = Oj.load(json)
    when Hash
      FluQ::Event.new hash, timestamp
    else
      logger.warn "buffer contained invalid event #{hash.inspect}"
      nil
    end
  rescue Oj::ParseError, ArgumentError
    logger.warn "buffer contained invalid line #{raw.inspect}"
    nil
  end

end
