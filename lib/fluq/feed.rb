module FluQ::Feed
end

%w'base msgpack'.each do |name|
  require "fluq/feed/#{name}"
end