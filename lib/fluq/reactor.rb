class FluQ::Reactor
  include FluQ::Mixins::Loggable

  # attr_reader [Celluloid::SupervisionGroup] inputs
  attr_reader :inputs

  # attr_reader [Hash] handlers
  attr_reader :handlers

  def initialize(*)
    super
    @inputs   = Celluloid::SupervisionGroup.new
    @handlers = {}
  end

  # Listens to an input
  # @param [Class<FluQ::Input::Base>] klass input class
  # @param [multiple] args initialization arguments
  def listen(klass, *args)
    logger.info "Listening to #{klass.name}"
    member = inputs.supervise(klass, self, *args)
    member.actor
  end

  # Registers a handler
  # @param [Class<FluQ::Handler::Base>] klass handler class
  # @param [multiple] args initialization arguments
  def register(klass, *args)
    logger.info "Registered #{klass.name}"
    handler = klass.new(*args)
    raise ArgumentError, "Handler '#{handler.name}' is already registered. Please provide a unique :name option" if handlers.key?(handler.name)
    handlers[handler.name] = handler
  end

  # @param [Array<Event>] events to process
  def process(events)
    handlers.each do |_, handler|
      matching = handler.select(events)
      handler.on_events(matching) unless matching.empty?
    end
    true
  end

end
