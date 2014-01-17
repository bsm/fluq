class FluQ::Feed::Json < FluQ::Feed::Lines

  # @see FluQ::Feed::Base.to_event
  def self.to_event(raw)
    case hash = MultiJson.load(raw)
    when Hash
      FluQ::Event.new(hash)
    else
      logger.warn "buffer contained invalid event #{hash.inspect}"
      nil
    end
  rescue MultiJson::LoadError
    logger.warn "buffer contained invalid line #{raw.inspect}"
    nil
  end

end
