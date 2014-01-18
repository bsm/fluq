module FluQ::Handler
end

%w'base log noop'.each do |name|
  require "fluq/handler/#{name}"
end
