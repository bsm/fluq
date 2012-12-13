class FluQ::Reactor

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
    FluQ.logger.info "Listening to #{klass.name}"
    member = inputs.supervise(klass, self, *args)
    member.actor
  end

  # Registers a handler
  # @param [Class<FluQ::Handler::Base>] klass handler class
  # @param [multiple] args initialization arguments
  def register(klass, *args)
    FluQ.logger.info "Registered #{klass.name}"
    handler = klass.new(*args)
    raise ArgumentError, "Handler '#{handler.name}' is already registered. Please provide a unique :name option" if handlers.key?(handler.name)
    handlers[handler.name] = handler
  end

  # @see FluQ::Event#initialize
  def process(tag, timestamp, record)
    event = FluQ::Event.new(tag, timestamp, record)
    handlers.each {|_, handler| handler.on_event(event) if handler.match?(event) }
    true
  end

end
