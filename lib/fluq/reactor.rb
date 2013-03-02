class FluQ::Reactor
  include FluQ::Mixins::Loggable

  # attr_reader [Array] handlers
  attr_reader :handlers

  # attr_reader [Array] inputs
  attr_reader :inputs

  # attr_accessor [Integer] buffer size
  #   The max. number of events to buffer events before flushing to handlers.
  attr_reader :buffer_size

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
    @buffer      = []
  end

  # @param [Integer] value the max. number of events
  #   to buffer events before flushing to handlers. Set to nil to disable.
  def buffer_size=(value)
    @buffer_size = value
    flush_when_idle!
    @buffer_size
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
    if buffer_size
      flush_when_idle!
      @buffer.concat(events)
      buflen = @buffer.size
      on_events @buffer.shift(buflen + 1) if buflen >= buffer_size
    else
      on_events events
    end
    true
  end

  # @return [String] introspection
  def inspect
    "#<#{self.class.name} inputs: #{inputs.size}, handlers: #{handlers.size}>"
  end

  protected

    def on_events(events)
      handlers.each do |handler|
        begin
          matching = handler.select(events)
          handler.on_events(matching) unless matching.empty?
        rescue => ex
          logger.crash "#{handler.class.name} #{handler.name} failed: #{ex.class.name} #{ex.message}", ex
        end
      end
    end

  private

    def flush_when_idle!
      @flusher.cancel if @flusher
      if buffer_size
        @flusher = EM.add_periodic_timer(1) { process([]) }
      else
        @flusher = nil
      end
    end

end
