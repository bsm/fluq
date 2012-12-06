class Fluq::DSL
  attr_reader :path, :inputs, :handlers

  # @param [String] DSL script file path
  def initialize(path)
    @path = Pathname.new(path)
    @inputs   = []
    @handlers = []
  end

  # @param [Symbol] input type, e.g. :socket
  def input(type, &block)
    klass = Fluq::Input.const_get(type.to_s.capitalize)
    inputs.push [klass, Fluq::DSL::Options.new(&block).to_hash]
  end

  # @param [Symbol] handler type, e.g. :forward, :counter
  def handler(type, &block)
    klass = Fluq::Handler.const_get(type.to_s.capitalize)
    handlers.push [klass, Fluq::DSL::Options.new(&block).to_hash]
  end

  # Starts the components. Handlers first, then inputs.
  def run
    instance_eval(path.read)
    handlers.each {|klass, options| Fluq.reactor.register(klass, options) }
    inputs.each   {|klass, options| Fluq.reactor.listen(klass, options) }
  end

end


%w'options'.each do |name|
  require "fluq/dsl/#{name}"
end
