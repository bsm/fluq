class FluQ::Input::Base
  include FluQ::Mixins::Loggable

  # @attr_reader [FluQ::Reactor] reactor reference
  attr_reader :reactor

  # @attr_reader [Hash] config
  attr_reader :config

  # @param [FluQ::Reactor] reactor
  # @param [Hash] options varous configuration options
  def initialize(reactor, options = {})
    super()
    @reactor = reactor
    @config  = defaults.merge(options)
  end

  # @return [String] descriptive name
  def name
    @name ||= self.class.name.split("::")[-1].downcase
  end

  # Start the input
  def run
  end

  protected

    def defaults
      {}
    end

end
