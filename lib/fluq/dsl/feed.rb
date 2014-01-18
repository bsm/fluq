# Feed-level DSL configuration
class FluQ::DSL::Feed < FluQ::DSL::Base
  attr_reader :name, :inputs, :handlers

  def initialize(name, &block)
    @name     = name
    @inputs   = []
    @handlers = []
    instance_eval(&block)
  end

  # @param [Array<Symbol>] input type path, e.g. :socket
  def input(*type, &block)
    klass = constantize(:input, *type)
    inputs.push [klass, FluQ::DSL::Options.new(&block).to_hash]
  end

  # @param [Array<Symbol>] handler type path, e.g. :log, :counter
  def handler(*type, &block)
    klass = constantize(:handler, *type)
    handlers.push [klass, FluQ::DSL::Options.new(&block).to_hash]
  end

end
