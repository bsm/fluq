class FluQ::DSL::Options

  # Constructor
  # @yield options assigment
  def initialize(&block)
    @opts = {}
    instance_eval(&block)
  end

  # @return [Hash] options hash
  def to_hash
    @opts
  end

  protected

    def method_missing(name, *args, &block)
      if args[0]
        @opts[name.to_sym] = args[0]
      elsif block
        @opts[name.to_sym] = block
      else
        super
      end
    end

end
