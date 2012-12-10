require 'celluloid/rspec'

module FluQ::SpecHelpers

  def self.included(base)
    super
    base.instance_eval do
      let(:reactor) { FluQ::Reactor.new }
      after         { Celluloid.shutdown }
    end
  end

  def wait_for_tasks_to_finish!
    Celluloid::Actor.all.each do |actor|
      begin
        sleep 0.001 while actor.tasks.any? {|t| t.status == :running }
      rescue Celluloid::DeadActorError
      end
    end
    sleep Celluloid::TIMER_QUANTUM
  end

end

RSpec.configure do |c|
  c.include FluQ::SpecHelpers
end