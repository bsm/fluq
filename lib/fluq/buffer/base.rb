class FluQ::Buffer::Base
  extend Forwardable

  attr_reader :handler, :timers
  private     :handler, :timers

  # Constructor
  # @param [FluQ::Handler::Base] handler
  def initialize(handler)
    @handler    = handler
    @interval   = handler.config[:flush_interval].to_i
    @rate       = handler.config[:flush_rate].to_i
    @rate       = 10_000 unless (1..10_000).include?(@rate)
    @timers     = Timers.new
    @size       = Atomic.new(0)

    timers.every(@interval) { flush } if @interval > 0
  end

  # Flushes the buffer
  def flush
    shift do |buffer, *args|
      begin
        handler.on_flush(buffer)
        commit(buffer, *args)
      rescue FluQ::Handler::Buffered::FlushError => e
        revert(buffer, *args)
      end
    end
    @flushed_at = Time.now
  end

  # @abstract
  # @param [FluQ::Event] an event to buffer
  def push(event)
    on_event(event)
    flush unless size < @rate
  end

  # @abstract
  # @return [Integer] size
  def size
    @size.value
  end

  protected

    # @abstract
    # On event callback
    def on_event(event)
    end

    # @abstract
    # @yieldparam [Array<FluQ::Event>] buffer buffered events
    # @yieldparam [Array] chunk committable/revertable chunk
    def shift
      yield([])
    end

    # @abstract
    # @param [Array] buffer events that has been flushed
    # @param [multiple] args optional args
    def commit(buffer, *args)
    end

    # @abstract
    # @param [Array] buffer events to revert and return to the stack
    # @param [multiple] args optional args
    def revert(buffer, *args)
    end

end