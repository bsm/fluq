module Fluq::Input
end

%w'socket'.each do |name|
  require "fluq/input/#{name}"
end