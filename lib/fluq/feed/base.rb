class FluQ::Feed::Base
  include Enumerable
  include FluQ::Mixins::Loggable
  extend FluQ::Mixins::Loggable

  # @abstract enumerator
  # @param [String] raw event string
  # @return [FluQ::Event] event
  def self.to_event(raw)
  end

  # @attr_reader [FluQ::Buffer::Base] buffer
  attr_reader :buffer

  # @param [FluQ::Buffer::Base] buffer
  def initialize(buffer)
    @buffer = buffer
  end

  # @yield ober a feed of events
  # @yieldparam [FluQ::Event] event
  def each
    each_raw do |raw|
      event = self.class.to_event(raw)
      yield event if event
    end
  end

  protected

    # @abstract enumerator
    # @yield ober a feed of raw events
    # @yieldparam [String] raw event
    def each_raw
    end

end