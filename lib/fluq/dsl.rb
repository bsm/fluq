module FluQ::DSL
end

%w'base root feed options'.each do |name|
  require "fluq/dsl/#{name}"
end
