module FluQ::Mixins::Logger

  def exception_handlers
    @exception_handlers ||= []
  end

  def exception_handler(&block)
    exception_handlers << block
  end

  def crash(string, exception)
    error(string)

    exception_handlers.each do |handler|
      begin
        handler.call(exception)
      rescue => ex
        error "EXCEPTION HANDLER CRASHED: #{ex.message}"
      end
    end
  end

end