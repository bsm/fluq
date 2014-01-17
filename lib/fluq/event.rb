class FluQ::Event < Hash

  attr_accessor :timestamp
  attr_reader :meta

  # @param [Hash] record the attribute pairs
  # @param [Integer] timestamp the UNIX timestamp
  def initialize(record = {}, timestamp = Time.now)
    @timestamp = timestamp.to_i
    @meta = {}
    super()
    update(record) if Hash === record
  end

  # @return [Time] UTC time
  def time
    @time ||= Time.at(timestamp).utc
  end

  # @return [Boolean] true if comparable
  def ==(other)
    case other
    when FluQ::Event
      super && other.timestamp == timestamp
    else
      super
    end
  end
  alias :eql? :==

  # @return [String] inspection
  def inspect
    "#<FluQ::Event(#{timestamp}) data:#{super} meta:#{meta.inspect}>"
  end

end
