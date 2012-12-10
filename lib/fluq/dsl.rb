class FluQ::DSL
  attr_reader :path, :reactor, :inputs, :handlers

  # @param [FluQ::Reactor] reactor
  # @param [String] DSL script file path
  def initialize(reactor, path)
    @reactor  = reactor
    @path     = Pathname.new(path)
    @inputs   = []
    @handlers = []
  end

  # @param [Symbol] input type, e.g. :socket
  def input(type, &block)
    klass = FluQ::Input.const_get(type.to_s.capitalize)
    inputs.push [klass, FluQ::DSL::Options.new(&block).to_hash]
  end

  # @param [Symbol] handler type, e.g. :forward, :counter
  def handler(type, &block)
    klass = FluQ::Handler.const_get(type.to_s.capitalize)
    handlers.push [klass, FluQ::DSL::Options.new(&block).to_hash]
  end

  # @param [String] relative relative path
  def import(relative)
    instance_eval(path.dirname.join(relative).read)
  end

  # Starts the components. Handlers first, then inputs.
  def run
    instance_eval(path.read)
    handlers.each {|klass, options| reactor.register(klass, options) }
    inputs.each   {|klass, options| reactor.listen(klass, options) }
  end

end

%w'options'.each do |name|
  require "fluq/dsl/#{name}"
end
