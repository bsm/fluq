class FluQ::Feed::Base
  include Enumerable
  include FluQ::Mixins::Loggable

  # @attr_reader [FluQ::Buffer::Base] buffer
  attr_reader :buffer

  # @param [FluQ::Buffer::Base] buffer
  def initialize(buffer)
    @buffer = buffer
  end

  # @abstract enumerator
  # @yield ober a feed of events
  # @yieldparam [FluQ::Event] event
  def each
  end
end