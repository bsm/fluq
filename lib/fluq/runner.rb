class FluQ::Runner
  include FluQ::Mixins::Loggable

  # Runs the runner (blocking)
  def self.run(&block)
    new(&block).run
  end

  # Constructor
  def initialize(&block)
    @feeds = Celluloid::SupervisionGroup.new
    block.call(self) if block
  end

  # @return [Array<FluQ::Feed>]
  def feeds
    @feeds.actors
  end

  # Registers a new feed
  # @param [String] name
  def feed(name, &block)
    @feeds.supervise FluQ::Feed, name, &block
  end

  # Starts the runner, blocking
  def run
    loop { sleep 5 while @feeds.alive? }
  end

  # Terminates the runner
  def terminate
    @feeds.terminate
  end

  # @return [String] introspection
  def inspect
    "#<#{self.class.name} feeds: #{feeds.map(&:name).inspect}>"
  end

end
