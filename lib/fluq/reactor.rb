class Fluq::Reactor

  # attr_reader [Hash] handlers
  attr_reader :handlers

  def initialize
    @handlers = {}
  end

  # Registers a handler
  # @param [Fluq::Handler::Base] handler
  def register(handler)
    raise ArgumentError, "Handler '#{handler.name}' is already registered. Please provide a unique :name option" if handlers.key?(handler.name)
    handlers[handler.name] = handler
  end

  # @see Fluq::Event#initialize
  def process(tag, timestamp, record)
    event = Fluq::Event.new(tag, timestamp, record)
    handlers.values.map do |instance|
      instance.on_event(event) || true if instance.match?(event)
    end.any?
  end

end