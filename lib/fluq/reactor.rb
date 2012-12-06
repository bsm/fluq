class FluQ::Reactor

  class Worker
    include Celluloid

    # @param [FluQ::Handler::Base] handler
    # @param [FluQ::Event] event
    def process(handler, event)
      handler.on_event(event) if handler.match?(event)
    end
  end

  # attr_reader [Celluloid::SupervisionGroup] inputs
  attr_reader :inputs

  # attr_reader [Hash] handlers
  attr_reader :handlers

  # attr_reader [Celluloid::PoolManager] workers
  attr_reader :workers

  def initialize(*)
    super
    @inputs   = Celluloid::SupervisionGroup.new
    @handlers = {}
    @workers  = FluQ::Reactor::Worker.pool
  end

  # Listens to an input
  # @param [Class<FluQ::Input::Base>] klass input class
  # @param [multiple] args initialization arguments
  def listen(klass, *args)
    member = inputs.supervise(klass, *args)
    member.actor
  end

  # Registers a handler
  # @param [Class<FluQ::Handler::Base>] klass handler class
  # @param [multiple] args initialization arguments
  def register(klass, *args)
    handler = klass.new(*args)
    raise ArgumentError, "Handler '#{handler.name}' is already registered. Please provide a unique :name option" if handlers.key?(handler.name)
    handlers[handler.name] = handler
  end

  # @see FluQ::Event#initialize
  def process(tag, timestamp, record)
    event = FluQ::Event.new(tag, timestamp, record)
    handlers.each {|_, handler| @workers.process!(handler, event) }
    true
  end

end
