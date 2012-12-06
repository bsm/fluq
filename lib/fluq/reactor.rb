class Fluq::Reactor

  class Fluq::Reactor::Worker
    include Celluloid

    # @param [Fluq::Handler::Base] handler
    # @param [Fluq::Event] event
    def process(handler, event)
      handler.on_event(event) if handler.match?(event)
    end
  end

  # attr_reader [Celluloid::SupervisorGroup] inputs
  attr_reader :inputs

  # attr_reader [Hash] handlers
  attr_reader :handlers

  # attr_reader [Celluloid::PoolManager] workers
  attr_reader :workers

  def initialize(*)
    super
    @inputs   = Celluloid::SupervisionGroup.new
    @handlers = {}
    @workers  = Fluq::Reactor::Worker.pool
  end

  # Listens to an input
  # @param [Class<Fluq::Input::Base>] klass input class
  # @param [multiple] args initialization arguments
  def listen(klass, *args)
    member = inputs.supervise(klass, *args)
    member.actor.run!
    member.actor
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
    handlers.each {|_, handler| @workers.process!(handler, event) }
    true
  end

end
