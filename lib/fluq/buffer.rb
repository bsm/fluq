module Fluq::Buffer
end

%w'base memory file'.each do |name|
  require "fluq/buffer/#{name}"
end