class FluQ::Feed::Json < FluQ::Feed::Base

  # @see FluQ::Feed::Base.to_event
  def self.to_event(raw)
    case hash = Oj.load(raw)
    when Hash
      FluQ::Event.new hash.delete("="), hash.delete("@"), hash
    else
      logger.warn "buffer contained invalid event #{hash.inspect}"
      nil
    end
  rescue Oj::ParseError
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