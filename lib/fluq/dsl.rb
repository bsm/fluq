class FluQ::DSL
  attr_reader :path, :reactor, :inputs, :handlers

  # @param [FluQ::Reactor] reactor
  # @param [String] DSL script file path
  def initialize(reactor, path)
    @reactor  = reactor
    @path     = Pathname.new(path)
    @inputs   = []
    @handlers = []
    $LOAD_PATH.unshift FluQ.root.join('lib')
  end

  # @param [Array<Symbol>] input type path, e.g. :socket
  def input(*type, &block)
    klass = constantize(:input, *type)
    inputs.push [klass, FluQ::DSL::Options.new(&block).to_hash]
  end

  # @param [Array<Symbol>] handler type path, e.g. :forward, :counter
  def handler(*type, &block)
    klass = constantize(:handler, *type)
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

  protected

    def constantize(*path)
      require([:fluq, *path].join('/'))
      names = path.map {|p| p.to_s.split('_').map(&:capitalize).join }
      names.inject(FluQ) {|klass, name| klass.const_get(name) }
    end

end

%w'options'.each do |name|
  require "fluq/dsl/#{name}"
end
