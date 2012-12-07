class FluQ::DSL::Options

  # Constructor
  # @yield options assigment
  def initialize(&block)
    @opts = {}
    instance_eval(&block) if block
  end

  # @return [Hash] options hash
  def to_hash
    @opts
  end

  protected

    def method_missing(name, *args, &block)
      value = args[0]
      if value && block
        @opts[name.to_sym] = value
        @opts[:"#{name}_options"] = self.class.new(&block).to_hash
      else
        @opts[name.to_sym] = value || block || true
      end
    end

end
