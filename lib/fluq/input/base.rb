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

  protected

    def defaults
      {}
    end

end
