class FluQ::Scheduler < ::Timers
  include FluQ::Mixins::Loggable

  attr_reader :runner
  private :runner

  # @see ::Timers#add
  def add(*)
    super.tap { reschedule! }
  end

  # @see ::Timers#fire
  def fire(*)
    super.tap { reschedule! }
  end

  # @see ::Timers#delete
  def delete(*)
    super.tap { reschedule! }
  end
  alias_method :cancel, :delete

  private

    def reschedule!
      if empty?
        @runner.exit if @runner && @runner.alive?
      elsif @runner.nil? || !@runner.alive?
        @runner = Thread.new { loop { wait_and_fire } }
      end
    end

    def wait_and_fire
      sleep(1) while empty?
      wait
    rescue => e
      logger.warn "#{self.class.name} task failed: #{e.message}"
    end

end
