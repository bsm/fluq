class FluQ::Input::Socket::Connection < EventMachine::Connection
  include FluQ::Mixins::Loggable

  # Constructor
  # @param [FluQ::Reactor] reactor
  def initialize(reactor)
    super()
    @reactor = reactor
  end

  # Generate a new unpacker for each connection
  def post_init
    @pac = FluQ::Event::Unpacker.new
  end

  # Callback
  def receive_data(data)
    @pac.feed_slice(data, 100) do |events|
      @reactor.process(events)
    end
  rescue => ex
    logger.crash "#{self.class.name} failure: #{ex.message} (#{ex.class.name})", ex
  end

end
