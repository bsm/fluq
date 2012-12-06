class FluQ::Event < Hash

  attr_reader :tag, :timestamp

  # @param [String] tag the event tag
  # @param [Integer] timestamp the UNIX timestamp
  # @param [Hash] record the attribute pairs
  def initialize(tag, timestamp, record)
    @tag, @timestamp = tag.to_s, timestamp.to_i
    super()
    update(record) if Hash === record
  end

  # @return [Time] UTC time
  def time
    @time ||= Time.at(timestamp).utc
  end

  # @return [Array] tuple
  def to_a
    [tag, timestamp, self]
  end

  # @return [String] encoded bytes
  def encode
    MessagePack.pack(to_a)
  end

  # @return [Boolean] true if comparable
  def ==(other)
    case other
    when Array
      to_a == other
    else
      super
    end
  end
  alias :eql? :==

  def to_s
    "#{tag}\t#{timestamp}\t#{MultiJson.encode(self)}"
  end

  # @return [String] inspection
  def inspect
    [tag, timestamp, Hash.new.update(self)].inspect
  end

end

