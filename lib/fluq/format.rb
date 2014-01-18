module FluQ::Format
end

%w'base lines msgpack json tsv'.each do |name|
  require "fluq/format/#{name}"
end
