module FluQ::Handler
end

%w'base buffered forward log null'.each do |name|
  require "fluq/handler/#{name}"
end
