class Fluq::DSL
  attr_reader :path, :inputs, :handlers

  # @param [String] DSL script file path
  def initialize(path)
    @path = Pathname.new(path)
    @inputs, @handlers = [], []
  end

  # @param [Symbol] input type, e.g. :socket
  def input(type, &block)
    klass    = Fluq::Instance.const_get(type.to_s.capitalize)
    instance = klass.new(Fluq::DSL::Options.new(&block))
    inputs.push find_input(type).new(options)
  end

  # @param [Symbol] handler type, e.g. :forward, :counter
  def handler(type, &block)
    klass    = Fluq::Handler.const_get(type.to_s.capitalize)
    instance = klass.new(Fluq::DSL::Options.new(&block))
    handlers.push(instance)
  end

  def run
    instance_eval(path.read)
    handlers.each do |handler|
      Fluq::Reactor.register(handler)
    end
    inputs.each &:run
  end

end


%w'options'.each do |name|
  require "fluq/dsl/#{name}"
end
