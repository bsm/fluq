class FluQ::Input::Base
  include FluQ::Mixins::Loggable

  # @attr_reader [FluQ::Reactor] reactor reference
  attr_reader :reactor

  # @attr_reader [Hash] config
  attr_reader :config

  # @param [FluQ::Reactor] reactor
  # @param [Hash] options various configuration options
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

    def buffer_klass
      @buffer_klass ||= FluQ::Buffer.const_get(config[:buffer].to_s.capitalize)
    end

    def feed_klass
      @feed_klass ||= FluQ::Feed.const_get(config[:feed].to_s.capitalize)
    end

    def defaults
      { buffer: "file", feed: "msgpack", buffer_options: {} }
    end

end
