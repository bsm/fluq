module Fluq::Handler
end

%w'base buffered forward'.each do |name|
  require "fluq/handler/#{name}"
end