class FluQ::Input::Socket::Connection < EventMachine::Connection
  include FluQ::Mixins::Loggable

  attr_reader :queue

  # Constructor
  # @param [FluQ::Reactor] reactor
  def initialize(reactor)
    super()
    @reactor = reactor
    @pac     = FluQ::Event::Unpacker.new
    @queue   = Queue.new
    reschedule!
  end

  # Callback
  def receive_data(data)
    reschedule!
    @pac.feed_each(data) do |event|
      @queue << event
    end
  rescue => ex
    logger.crash "#{self.class.name} failure: #{ex.message} (#{ex.class.name})", ex
  end

  private

    def flush!
      events = []
      loop { events << @queue.pop(true) } rescue nil
      @reactor.process(events) unless events.empty?
    end

    def reschedule!
      @timer.cancel if @timer
      @timer = EM.add_periodic_timer(0.1) { flush! }
    end

end
