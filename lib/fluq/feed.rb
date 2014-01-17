module FluQ::Feed
end

%w'base lines msgpack json tsv'.each do |name|
  require "fluq/feed/#{name}"
end
