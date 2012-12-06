class FluQ::Reactor

  class FluQ::Reactor::Worker
    include Celluloid

    # @param [FluQ::Handler::Base] handler
    # @param [FluQ::Event] event
    def process(handler, event)
      handler.on_event(event) if handler.match?(event)
    end
  end

  # attr_reader [Array] inputs
  attr_reader :inputs

  # attr_reader [Hash] handlers
  attr_reader :handlers

  # attr_reader [Celluloid::PoolManager] workers
  attr_reader :workers

  def initialize(*)
    super
    @inputs   = []
    @handlers = {}
    @workers  = FluQ::Reactor::Worker.pool
  end

  # Listens to an input
  # @param [Class<FluQ::Input::Base>] klass input class
  # @param [multiple] args initialization arguments
  def listen(klass, *args)
    input = klass.new(*args)
    inputs.push(input)
    input.run!
    input
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

  # Terminate on shutdown
  def terminate
    inputs.each(&:terminate)
    workers.terminate
  end

end
