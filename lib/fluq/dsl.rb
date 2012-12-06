class Fluq::Dsl
  attr_reader :path, :inputs, :handlers

  # @param [String] DSL script file path
  def initialize(path)
    @path = Pathname.new(path)
    @inputs, @handlers = [], []
  end

  # @param [Symbol] input type, e.g. :socket
  def input(type, &block)
    options = build_options(block)
    self.inputs << find_input(type).new(options)
  end

  # @param [Symbol] handler type, e.g. :forward, :counter
  def handler(type, &block)
    options = build_options(block)
    self.handlers << find_handler(type).new(options)
  end

  def run
    instance_eval(path.read)

    self.handlers.each do |handler|
      Fluq::Reactor.register(handler)
    end
    self.inputs.each &:run
  end

  protected

    def find_input(type)
      Fluq::Input.const_get(type.to_s.capitalize)
    end

    def find_handler(type)
      Fluq::Handler.const_get(type.to_s.capitalize)
    end

    def build_options(block)
      Fluq::Dsl::Options.new.tap {|opts| opts.instance_eval(&block) }
    end

end


%w'options'.each do |name|
  require "fluq/dsl/#{name}"
end
