class FluQ::Event::Unpacker
  include Enumerable

  # @param [IO] io the IO to read from
  def initialize(io)
    super()
    @pac = MessagePack::Unpacker.new(io)
  end

  # @yield over events
  # @yieldparam [Event] event
  def each
    @pac.each do |tag, timestamp, record|
      event = FluQ::Event.new(tag, timestamp, record)
      yield event
    end
  rescue EOFError
    @pac.stream.close
  end

end
