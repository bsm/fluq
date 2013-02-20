class FluQ::Scheduler < ::Timers
  include FluQ::Mixins::Loggable

  attr_reader :runner
  private :runner

  def initialize(*)
    super
    @runner = Thread.new { loop { wait_and_fire } }
  end

  private

    def wait_and_fire
      sleep(1) while empty?
      wait
    rescue => e
      logger.crash "#{self.class.name} task failed", e
    end

end
