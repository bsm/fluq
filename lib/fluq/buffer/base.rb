class FluQ::Buffer::Base
  extend Forwardable
  include FluQ::Mixins::Loggable

  attr_reader :handler, :timers, :rate, :interval
  private     :handler, :timers, :rate, :interval

  # @attr_reader [Hash] config configuration
  attr_reader :config

  # Constructor
  # @param [FluQ::Handler::Base] handler
  # @param [Hash] options various options
  def initialize(handler, options = {})
    @handler    = handler
    @config     = defaults.merge(options)
    @interval   = handler.config[:flush_interval].to_i
    @rate       = handler.config[:flush_rate].to_i
    @rate       = 10_000 unless (1..10_000).include?(@rate)
    @timers     = Timers.new
    @size       = Atomic.new(0)

    timers.every(interval) { flush } if interval > 0
  end

  # Flushes the buffer
  def flush
    logger.debug { "#{self.class.name}#flush size: #{size}" }
    shift do |buffer, *args|
      begin
        handler.on_flush(buffer)
        commit(buffer, *args)
      rescue FluQ::Handler::Buffered::FlushError => e
        revert(buffer, *args)
      end
    end
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

    # @abstract
    # @return [Hash] default options
    def defaults
      {}
    end

end