module FluQ::Handler
end

%w'base buffered forward log log/file_pool null'.each do |name|
  require "fluq/handler/#{name}"
end
