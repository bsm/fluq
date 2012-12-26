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
    return if @pac.buffer.io.closed?

    @pac.each do |tag, timestamp, record|
      yield FluQ::Event.new(tag, timestamp, record)
    end
  rescue EOFError
    @pac.buffer.io.close
  end

end
