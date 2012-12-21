class FluQ::Event::Unpacker
  include Enumerable

  # @param [IO] io the IO to read from
  def initialize(io)
    super()
    @io  = io
    @pac = MessagePack::Unpacker.new(@io)
  end

  # @yield over events
  # @yieldparam [Event] event
  def each
    return if @io.closed?

    @pac.each do |tag, timestamp, record|
      yield FluQ::Event.new(tag, timestamp, record)
    end
  rescue EOFError
    @io.close
  end

end
