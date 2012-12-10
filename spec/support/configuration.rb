require 'celluloid/rspec'

module FluQ::SpecHelpers

  def self.included(base)
    super
    base.let(:reactor) { @reactor = FluQ::Reactor.new }
  end

end

RSpec.configure do |c|
  c.include FluQ::SpecHelpers
  c.after { @reactor.terminate if @reactor }
end