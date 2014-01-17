class FluQ::Input::Base
  include Celluloid::IO
  include FluQ::Mixins::Loggable
  finalizer :before_terminate

  # @attr_reader [Hash] config
  attr_reader :config

  # @param [FluQ::Reactor] reactor
  # @param [Hash] options various configuration options
  def initialize(reactor, options = {})
    super()
    @config = defaults.merge(options)
    @supviz = FluQ::Worker.supervise reactor.handlers
  end

  # @return [String] descriptive name
  def name
    @name ||= self.class.name.split("::")[-1].downcase
  end

  # Start the input
  def run
    logger.info "Listening to #{name}"
  end

  # Processes data
  # @param [String] data
  def process(data)
    worker.process feed.parse(data)
  end

  # @attr_reader [FluQ::Worker] worker instance
  def worker
    @supviz.actors.first
  end

  protected

    # @abstract callback after initialize termination
    def after_initialize
    end

    # @abstract callback before termination
    def before_terminate
    end

    def feed
      @feed ||= FluQ::Feed.const_get(config[:feed].to_s.capitalize).new(config[:feed_options])
    end

    def defaults
      { feed: "json", feed_options: {} }
    end

end
