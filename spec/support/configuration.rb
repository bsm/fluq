RSpec.configure do |c|
  c.after do
    Fluq.reactor.handlers.clear
  end
end

