class FluQ::Buffer::Base
  extend Forwardable
  include FluQ::Mixins::Loggable

  attr_reader :handler, :rate, :timer, :interval
  private     :handler, :rate, :timer, :interval

  # @attr_reader [Hash] config configuration
  attr_reader :config

  # Constructor
  # @param [FluQ::Handler::Base] handler
  # @param [Hash] options various options
  def initialize(handler, options = {})
    @handler  = handler
    @config   = defaults.merge(options)
    @interval = handler.config[:flush_interval].to_i
    @rate     = handler.config[:flush_rate].to_i
    @rate     = 100_000 unless (1..100_000).include?(@rate)
    @size     = Atomic.new(0)
    @timer    = FluQ.timers.every(interval) { flush } if interval > 0
  end

  # Flushes the buffer
  def flush
    @size.update {|*| 0 }
    shift do |buffer, opts|
      logger.debug { "#{self.class.name}#flush size: #{buffer.size}" }
      begin
        handler.on_flush(buffer)
        commit(buffer, opts)
      rescue FluQ::Handler::Buffered::FlushError => e
        @size.update {|v| v + buffer.size }
        revert(buffer, opts)
      end
    end
  end

  # @abstract
  # @param [FluQ::Event] an event to buffer
  def push(event)
    on_event(event)
    @size.update {|v| v + 1 }
    unless size < rate
      timer.reset if timer
      flush
    end
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
    # @yieldparam [Hash] options
    def shift
      yield([], {})
    end

    # @abstract
    # @param [Array] buffer events that has been flushed
    # @param [Hash] options
    def commit(buffer, opts = {})
    end

    # @abstract
    # @param [Array] buffer events to revert and return to the stack
    # @param [Hash] options
    def revert(buffer, opts = {})
    end

    # @abstract
    # @return [Hash] default options
    def defaults
      {}
    end

end
