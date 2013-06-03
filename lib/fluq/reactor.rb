class FluQ::Reactor
  include FluQ::Mixins::Loggable

  # attr_reader [Array] handlers
  attr_reader :handlers

  # attr_reader [Array] inputs
  attr_reader :inputs

  # Runs the reactor within EventMachine
  def self.run
    EM.run do
      EM.threadpool_size = 100
      yield new
    end
  end

  # Constructor
  def initialize
    super
    @handlers    = []
    @inputs      = []
  end

  # Listens to an input
  # @param [Class<FluQ::Input::Base>] klass input class
  # @param [multiple] args initialization arguments
  def listen(klass, *args)
    input = klass.new(self, *args).tap(&:run)
    inputs.push(input)
    logger.info "Listening to #{input.name}"
    input
  end

  # Registers a handler
  # @param [Class<FluQ::Handler::Base>] klass handler class
  # @param [multiple] args initialization arguments
  def register(klass, *args)
    handler = klass.new(self, *args)
    if handlers.any? {|h| h.name == handler.name }
      raise ArgumentError, "Handler '#{handler.name}' is already registered. Please provide a unique :name option"
    end
    handlers.push(handler)
    logger.info "Registered #{handler.name}"
    handler
  end

  # @param [Array<Event>] events to process
  def process(events)
    on_events events
    true
  end

  # @return [String] introspection
  def inspect
    "#<#{self.class.name} inputs: #{inputs.size}, handlers: #{handlers.size}>"
  end

  protected

    def on_events(events)
      handlers.each do |handler|
        start = Time.now
        begin
          matching = handler.select(events)
          next if matching.empty?

          handler.on_events(matching)
          logger.info { "#{handler.name} processed #{matching.size}/#{events.size} events in #{((Time.now - start) * 1000).round}ms" }
        rescue => ex
          logger.crash "#{handler.class.name} #{handler.name} failed: #{ex.class.name} #{ex.message}", ex
        end
      end
    end

end
