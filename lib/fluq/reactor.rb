class FluQ::Reactor < Celluloid::SupervisionGroup
  include FluQ::Mixins::Loggable

  # attr_reader [Hash] handlers
  attr_reader :handlers

  # attr_reader [FluQ::Scheduler] scheduler
  attr_reader :scheduler

  def initialize
    super
    @handlers  = {}
    @scheduler = FluQ::Scheduler.new
  end

  # Listens to an input
  # @param [Class<FluQ::Input::Base>] klass input class
  # @param [multiple] args initialization arguments
  def listen(klass, *args)
    logger.info "Listening to #{klass.name}"
    supervise(klass, current_actor, *args).actor
  end

  # Registers a handler
  # @param [Class<FluQ::Handler::Base>] klass handler class
  # @param [multiple] args initialization arguments
  def register(klass, *args)
    logger.info "Registered #{klass.name}"
    handler = supervise(klass, current_actor, *args).actor
    raise ArgumentError, "Handler '#{handler.name}' is already registered. Please provide a unique :name option" if handlers.key?(handler.name)
    handlers[handler.name] = handler
  end

  # @param [Array<Event>] events to process
  def process(events)
    handlers.each do |_, handler|
      matching = handler.select(events)
      handler.async.on_events(matching) unless matching.empty?
    end
    true
  end

end
