class FluQ::Format::Base
  include FluQ::Mixins::Loggable
  extend FluQ::Mixins::Loggable

  # @abstract converter
  # @param [String] raw event string
  # @return [FluQ::Event] event
  def self.to_event(raw)
  end

  # @abstract initializer
  # @param [Hash] options format-specific options
  def initialize(options = {})
    @options = options
  end

  # @abstract parse data, return events
  # @param [String] data
  # @return [Array<FluQ::Event>] events
  def parse(data)
    events = []
    parse_each(data) do |raw|
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
    # @yield over raw events
    # @yieldparam [Hash] raw event data
    def parse_each(data)
    end

end
