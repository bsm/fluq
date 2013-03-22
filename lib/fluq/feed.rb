module FluQ::Feed
end

%w'base msgpack json tsv'.each do |name|
  require "fluq/feed/#{name}"
end