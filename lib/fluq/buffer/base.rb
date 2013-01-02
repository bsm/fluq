class FluQ::Buffer::Base
  extend Forwardable
  include Celluloid
  include FluQ::Mixins::Loggable

  attr_reader :handler, :flusher, :rate, :interval

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
    @counter  = Atomic.new(0)

    me = current_actor
    @flusher  = @handler.reactor.scheduler.every(interval) { me.flush } if interval > 0
  end

  # Flushes the buffer
  def flush
    return if event_count.zero?

    @counter.update {|_| 0 }
    flusher.reset if flusher
    async.do_flush
  end

  # @abstract
  # @param [Array<FluQ::Event>] events events to buffer
  def concat(events)
    on_events(events)
    @counter.update {|v| v + events.size }
    unless event_count < rate
      flush
    end
  end

  # @abstract
  # @return [Integer] event count
  def event_count
    @counter.value
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
        break
      end
    end
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
