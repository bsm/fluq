module FluQ::Mixins
end

%w'loggable logger'.each do |name|
  require "fluq/mixins/#{name}"
end