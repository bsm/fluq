class FluQ::Event < Hash

  attr_reader :tag, :timestamp

  # @param [String] tag the event tag
  # @param [Integer] timestamp the UNIX timestamp
  # @param [Hash] record the attribute pairs
  def initialize(tag = "", timestamp = 0, record = {})
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

  # @return [String] tab-separated string
  def to_tsv
    [tag, timestamp, Oj.dump(self)].join("\t")
  end

  # @return [String] JSON encoded
  def to_json
    Oj.dump merge("=" => tag, "@" => timestamp)
  end

  # @return [String] mgspack encoded bytes
  def to_msgpack
    MessagePack.pack merge("=" => tag, "@" => timestamp)
  end

  # @return [String] inspection
  def inspect
    [tag, timestamp, Hash.new.update(self)].inspect
  end

end
