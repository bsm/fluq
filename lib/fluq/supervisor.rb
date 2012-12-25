class FluQ::Supervisor < Celluloid::SupervisionGroup
  include Enumerable
  extend  Forwardable
  def_delegators :@members, :each
end