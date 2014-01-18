class FluQ::Input::Base
  include Celluloid::IO
  include FluQ::Mixins::Loggable
  finalizer :before_terminate

  # @attr_reader [Hash] config
  attr_reader :config

  # @param [Array<Class,multiple>] handlers handler builders
  # @param [Hash] options various configuration options
  def initialize(handlers, options = {})
    super()
    @config = defaults.merge(options)
    configure
    @sup = FluQ::Worker.supervise name, handlers
  end

  # @return [String] short name
  def name
    @name ||= self.class.name.split("::")[-1].downcase
  end

  # @return [String] descriptive name
  def description
    name
  end

  # Start the input
  def run
    logger.info "Listening to #{description}"
  end

  # Processes data
  # @param [String] data
  def process(data)
    worker.process format.parse(data)
  end

  # @attr_reader [FluQ::Worker] worker instance
  def worker
    @sup.actors.first
  end

  protected

    # @abstract callback for configuration initialization
    def configure
    end

    # @abstract callback before termination
    def before_terminate
    end

    def format
      @format ||= FluQ::Format.const_get(config[:format].to_s.capitalize).new(config[:format_options])
    end

    def defaults
      { format: "json", format_options: {} }
    end

end
