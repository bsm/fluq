require 'celluloid/rspec'

RSpec.configure do |c|
  c.after do
    # FluQ.reactor.inputs.finalize
    FluQ.reactor.inputs.__reset__
    FluQ.reactor.handlers.clear
  end
end

