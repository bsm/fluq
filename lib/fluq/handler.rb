module FluQ::Handler
end

%w'base log null'.each do |name|
  require "fluq/handler/#{name}"
end
