class FluQ::Input::Socket::Connection < EventMachine::Connection
  include FluQ::Mixins::Loggable

  # Constructor
  # @param [FluQ::Input::Socket] parent the input
  def initialize(parent)
    super()
    @parent = parent
  end

  # Callback
  def post_init
    self.comm_inactivity_timeout = 60
  end

  # Callback
  def receive_data(data)
    buffer.write(data)
    flush! if buffer.full?
  rescue => ex
    logger.crash "#{self.class.name} failure: #{ex.message} (#{ex.class.name})", ex
  end

  # Callback
  def unbind
    flush!
  end

  protected

    def buffer
      @buffer ||= @parent.new_buffer
    end

    def flush!
      current = buffer
      @buffer = nil
      @parent.flush!(current)
    end

end
