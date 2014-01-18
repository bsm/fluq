class FluQ::Feed
  include Celluloid

  # @attr_reader [String] name
  attr_reader :name

  # @attr_reader [Array] handlers
  attr_reader :handlers

  # Constructor
  # @param [String] name feed name
  def initialize(name, &block)
    @name     = name.to_s
    @sup      = Celluloid::SupervisionGroup.new
    @handlers = []
    block.call(self) if block
  end

  # @return [Array<FluQ::Input::Base>] inputs
  def inputs
    @sup.actors
  end

  # Listens to an input
  # @param [Class<FluQ::Input::Base>] klass input class
  # @param [multiple] args initialization arguments
  def listen(klass, *args)
    @sup.supervise klass, handlers, *args
  end

  # Registers a handler
  # @param [Class<FluQ::Handler::Base>] klass handler class
  # @param [multiple] args initialization arguments
  def register(klass, *args)
    handlers.push [klass, *args]
  end

  # @return [String] introspection
  def inspect
    "#<#{self.class.name}(#{name}) inputs: #{inputs.size}, handlers: #{handlers.size}>"
  end

end
