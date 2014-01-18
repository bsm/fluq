class FluQ::Format::Tsv < FluQ::Format::Lines

  # @see FluQ::Format::Base.to_event
  def self.to_event(raw)
    timestamp, json = raw.split("\t")

    case hash = MultiJson.load(json)
    when Hash
      FluQ::Event.new hash, timestamp
    else
      logger.warn "buffer contained invalid event #{hash.inspect}"
      nil
    end
  rescue MultiJson::LoadError, ArgumentError
    logger.warn "buffer contained invalid line #{raw.inspect}"
    nil
  end

end
