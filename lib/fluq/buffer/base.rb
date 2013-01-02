class FluQ::Buffer::Base
  extend Forwardable
  include Celluloid
  include FluQ::Mixins::Loggable

  attr_reader :handler, :rate, :interval

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

    every(interval) { flush } if interval > 0
  end

  # Flushes the buffer
  def flush
    return if size.zero?

    @size.update {|_| 0 }
    flusher.reset
    async.do_flush
  end

  # @abstract
  # @param [Array<FluQ::Event>] events events to buffer
  def concat(events)
    on_events(events)
    @size.update {|v| v + events.size }
    unless size < rate
      flush
    end
  end

  # @abstract
  # @return [Integer] size
  def size
    @size.value
  end

  # Execute flush, called async
  def do_flush
    shift do |buffer, opts|
      logger.debug { "#{self.class.name}#flush size: #{buffer.size}" }
      begin
        handler.on_flush(buffer)
        commit(buffer, opts)
      rescue FluQ::Handler::Buffered::FlushError => e
        revert(buffer, opts)
      end
    end
  end

  # @return [Timers::Timer] recurring flusher
  def flusher
    Thread.current[:actor].instance_variable_get(:@timers).first
  end

  protected

    # @abstract
    # On events callback
    def on_events(events)
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
