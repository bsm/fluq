module FluQ::Mixins
end

%w'loggable'.each do |name|
  require "fluq/mixins/#{name}"
end
