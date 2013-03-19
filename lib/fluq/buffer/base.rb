class FluQ::Buffer::Base
  include Enumerable

  MAX_SIZE = 256 * 1024 * 1024 # 256M

  # @attr_reader [Hash] config
  attr_reader :config

  # @param [Hash] options various configuration options
  def initialize(options = {})
    super()
    @config = defaults.merge(options)
  end

  # @abstract
  # @yield over events
  # @yieldparam [FluQ::Event] event
  def each
  end

  # @abstract
  # @return [Integer] the size
  def size
    0
  end

  # @return [Boolean] true if size exceeds limit
  def full?
    size >= config[:max_size]
  end

  # @abstract data writer
  # @param [String] data binary string
  def write(data)
  end

  # @abstract callback, close buffer
  def close
  end

  protected

    def defaults
      { max_size: MAX_SIZE }
    end

end
