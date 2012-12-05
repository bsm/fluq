RSpec.configure do |c|
  c.after do
    Fluq::Handler.registry.clear
  end
end

