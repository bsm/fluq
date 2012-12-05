class Fluq::Buffer::Base
  extend Forwardable

  attr_reader :handler, :flushed_at, :flusher
  private     :handler, :flushed_at, :flusher

  # Constructor
  # @param [Fluq::Handler::Base] handler
  def initialize(handler)
    @handler    = handler
    @flushed_at = Time.now - 1
    @interval   = handler.config[:flush_interval].to_i
    @rate       = handler.config[:flush_rate].to_i
    @rate       = 10_000 unless (1..10_000).include?(@rate)
    @flusher    = setup_flusher
  end

  # @return [Boolean] true if flush is due
  def due?
    interval_due? || rate_due?
  end

  # Flushes the buffer
  def flush
    shift do |buffer, *args|
      begin
        handler.on_flush(buffer)
        commit(buffer, *args)
      rescue Fluq::Handler::Buffered::FlushError => e
        revert(buffer, *args)
      end
    end
    @flushed_at = Time.now
  end

  # @abstract
  # @param [Fluq::Event] an event to buffer
  def push(event)
  end

  # @abstract
  # @return [Integer] size
  def size
    0
  end

  protected

    # @abstract
    # @yieldparam [Array<Fluq::Event>] buffer buffered events
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

  private

    def interval_due?
      @interval > 0 && (flushed_at + @interval) <= Time.now
    end

    def rate_due?
      events.size >= @rate
    end

    # Setup flusher
    def setup_flusher
      Thread.new do
        loop do
          sleep(1)
          flush if due?
        end
      end
    end

end