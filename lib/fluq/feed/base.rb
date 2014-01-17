class FluQ::Feed::Base
  include FluQ::Mixins::Loggable
  extend FluQ::Mixins::Loggable

  # @abstract converter
  # @param [String] raw event string
  # @return [FluQ::Event] event
  def self.to_event(raw)
  end

  # @abstract initializer
  # @param [Hash] options feed-specific options
  def initialize(options = {})
    @options = options
  end

  # @abstract parse data, return events
  # @param [String] data
  # @return [Array<FluQ::Event>] events
  def parse(data)
    events = []
    feed(data) do |raw|
      if event = self.class.to_event(raw)
        events.push(event)
        true
      else
        false
      end
    end
    events
  end

  protected

    # @abstract enumerator
    # @param [String] data
    # @yield over feed of raw events
    # @yieldparam [Hash] raw event data
    def feed(data)
    end

end
