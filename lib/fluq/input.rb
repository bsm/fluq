module FluQ::Input
end

%w'base socket'.each do |name|
  require "fluq/input/#{name}"
end