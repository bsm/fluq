class FluQ::Input::Socket::Connection < EventMachine::Connection
  include FluQ::Mixins::Loggable

  # Constructor
  # @param [FluQ::Reactor] reactor
  # @param [Class<FluQ::Feed::Base>] feed_klass
  # @param [Class<FluQ::Buffer::Base>] buffer_klass
  # @param [Hash] buffer_opts buffer options
  def initialize(reactor, feed_klass, buffer_klass, buffer_opts = {})
    super()
    @reactor = reactor
    @feed_klass   = feed_klass
    @buffer_klass = buffer_klass
    @buffer_opts  = buffer_opts
  end

  # Callback
  def post_init
    self.comm_inactivity_timeout = 60
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
      @buffer ||= @buffer_klass.new(@buffer_opts)
    end

    def process!
      current = buffer
      @buffer = nil
      @feed_klass.new(current).each_slice(10_000) do |events|
        @reactor.process(events)
      end
    rescue => ex
      logger.crash "#{self.class.name} failure: #{ex.message} (#{ex.class.name})", ex
    ensure
      current.close if current
    end

end
