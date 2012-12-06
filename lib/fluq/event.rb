class Fluq::Event < Hash

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
    to_a.to_msgpack
  end

end

