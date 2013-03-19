module FluQ::Buffer
end

%w'base file'.each do |name|
  require "fluq/buffer/#{name}"
end