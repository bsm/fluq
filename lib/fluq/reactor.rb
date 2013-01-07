class FluQ::Reactor
  include FluQ::Mixins::Loggable

  # attr_reader [Array] handlers
  attr_reader :handlers

  # attr_reader [Array] inputs
  attr_reader :inputs

  # attr_reader [FluQ::Scheduler] scheduler
  attr_reader :scheduler

  # Runs the reactor within EventMachine
  def self.run
    EM.run { yield new }
  end

  # Constructor
  def initialize
    super
    @handlers  = []
    @inputs    = []
    @scheduler = FluQ::Scheduler.new
  end

  # Listens to an input
  # @param [Class<FluQ::Input::Base>] klass input class
  # @param [multiple] args initialization arguments
  def listen(klass, *args)
    logger.info "Listening to #{klass.name}"
    input = klass.new(self, *args).tap(&:run)
    inputs.push(input)
    input
  end

  # Registers a handler
  # @param [Class<FluQ::Handler::Base>] klass handler class
  # @param [multiple] args initialization arguments
  def register(klass, *args)
    logger.info "Registered #{klass.name}"

    handler = klass.new(self, *args)
    if handlers.any? {|h| h.name == handler.name }
      raise ArgumentError, "Handler '#{handler.name}' is already registered. Please provide a unique :name option"
    end
    handlers.push(handler)
    handler
  end

  # @param [Array<Event>] events to process
  def process(events)
    handlers.each do |handler|
      begin
        matching = handler.select(events)
        handler.on_events(matching) unless matching.empty?
      rescue => ex
        Celluloid::Logger.crash "#{handler.class.name} #{handler.name} failed!", ex
      end
    end
    true
  end

  # @return [String] introspection
  def inspect
    "#<#{self.class.name} inputs: #{inputs.size}, handlers: #{handlers.size}>"
  end

end
