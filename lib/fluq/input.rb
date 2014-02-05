module FluQ::Input
end

%w'base noop socket'.each do |name|
  require "fluq/input/#{name}"
end
