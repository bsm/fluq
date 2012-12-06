module FluQ::Handler
end

%w'base buffered forward log'.each do |name|
  require "fluq/handler/#{name}"
end