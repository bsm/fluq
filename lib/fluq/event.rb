class FluQ::Event < Hash

  # @param [Hash] event the event record
  def initialize(event = {})
    super()
    update(event) if Hash === event
    normalize!
  end

  # @return [String] tag
  def tag
    self["_tag"]
  end

  # @return [Integer] timestamp
  def timestamp
    self["_ts"]
  end

  # @return [Time] UTC time
  def time
    @time ||= Time.at(timestamp).utc
  end

  # @return [String] encoded bytes
  def encode
    MessagePack.pack(self)
  end

  def to_s
    MultiJson.encode(self)
  end

  private

    def normalize!
      case self["_tag"]
      when String
        # Do nothing
      when Symbol
        self["_tag"] = self["_tag"].to_s
      else
        self["_tag"] = ""
      end

      case self["_ts"]
      when Fixnum
        # Do nothing
      when Time, Numeric, String
        self["_ts"] = self["_ts"].to_i
      else
        self["_ts"] = Time.now.to_i
      end
    end

end
