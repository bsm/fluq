class FluQ::Reactor
  include FluQ::Mixins::Loggable

  # attr_reader [Array] handlers
  attr_reader :handlers

  # attr_reader [Array] inputs
  attr_reader :inputs

  # Runs the reactor (blocking)
  def self.run(&block)
    new(&block).run
  end

  # Constructor
  def initialize(&block)
    @handlers = []
    @inputs   = []
    block.call(self) if block
  end

  # Listens to an input
  # @param [Class<FluQ::Input::Base>] klass input class
  # @param [multiple] args initialization arguments
  def listen(klass, *args)
    inputs.push([klass, *args])
  end

  # Registers a handler
  # @param [Class<FluQ::Handler::Base>] klass handler class
  # @param [multiple] args initialization arguments
  def register(klass, *args)
    handler = klass.new(*args)
    if handlers.any? {|h| h.name == handler.name }
      raise ArgumentError, "Handler '#{handler.name}' is already registered. Please provide a unique :name option"
    end
    handlers.push(handler)
    logger.info "Registered #{handler.name}"
    handler
  end

  # Starts the reactor
  def run
    root.run
  end

  # @return [Celluloid::SupervisionGroup] root supervisor
  def root
    @root ||= Celluloid::SupervisionGroup.new do |group|
      inputs.each do |klass, *args|
        group.supervise klass, self, *args
      end
    end
  end

  # @return [String] introspection
  def inspect
    "#<#{self.class.name} inputs: #{inputs.size}, handlers: #{handlers.size}>"
  end

end
