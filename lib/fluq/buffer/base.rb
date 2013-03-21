class FluQ::Buffer::Base
  MAX_SIZE = 256 * 1024 * 1024 # 256M

  # @attr_reader [Hash] config
  attr_reader :config

  # @param [Hash] options various configuration options
  def initialize(options = {})
    super()
    @config = defaults.merge(options)
  end

  # @return [String] name identifier
  def name
    @name ||= self.class.name.split("::").last.downcase
  end

  # @abstract
  # @yield over io object
  # @yieldparam [IO] io
  def drain
    yield StringIO.new
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
