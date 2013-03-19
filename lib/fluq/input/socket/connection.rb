class FluQ::Input::Socket::Connection < EventMachine::Connection
  include FluQ::Mixins::Loggable

  # Constructor
  # @param [FluQ::Reactor] reactor
  # @param [Hash] options buffer options
  def initialize(reactor, options = {})
    super()
    @reactor = reactor
    @options = options
  end

  # Callback
  def receive_data(data)
    buffer.write(data)
    process! if buffer.full?
  rescue => ex
    logger.crash "#{self.class.name} failure: #{ex.message} (#{ex.class.name})", ex
  end

  # Callback
  def unbind
    process!
  end

  protected

    def buffer
      @buffer ||= FluQ::Buffer::File.new(@options)
    end

    def process!
      current = buffer
      @buffer = nil
      current.each_slice(1_000) do |events|
        @reactor.process(events)
      end
    rescue => ex
      logger.crash "#{self.class.name} failure: #{ex.message} (#{ex.class.name})", ex
    ensure
      current.close if current
    end

end
