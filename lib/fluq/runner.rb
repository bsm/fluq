class FluQ::Runner
  include FluQ::Mixins::Loggable

  # Runs the runner (blocking)
  def self.run(&block)
    new(&block).run
  end

  # Constructor
  def initialize(&block)
    @sup = Celluloid::SupervisionGroup.new
    block.call(self) if block
  end

  # @return [Array<FluQ::Feed>]
  def feeds
    @sup.actors
  end

  # Registers a new feed
  # @param [String] name
  def feed(name, &block)
    @sup.supervise FluQ::Feed, name, &block
  end

  # Starts the runner, blocking
  def run
    loop { sleep 5 while @sup.alive? }
  end

  # @return [String] introspection
  def inspect
    "#<#{self.class.name} feeds: #{feeds.map(&:name).inspect}>"
  end

end
