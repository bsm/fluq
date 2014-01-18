# Root-level DSL configuration
class FluQ::DSL::Root < FluQ::DSL::Base
  attr_reader :path, :feeds

  # @param [String] DSL script file path
  def initialize(path)
    @path   = Pathname.new(path)
    @feeds  = []

    instance_eval path.read
  end

  # @param [String] feed name, e.g. "my_events"
  def feed(name, &block)
    feeds.push FluQ::DSL::Feed.new(name, &block)
  end

  # @param [String] relative relative path
  def import(relative)
    instance_eval path.dirname.join(relative).read
  end

  # Applies the configuration.
  # Registers components of each feed. Handlers first, then inputs.
  # @param [FluQ::Runner] runner
  def apply(runner)
    feeds.each do |conf|
      runner.feed conf.name do |feed|
        conf.handlers.each {|k, *a| feed.register(k, *a) }
        conf.inputs.each   {|k, *a| feed.listen(k, *a) }
      end
    end
  end

end
