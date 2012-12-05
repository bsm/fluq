module Fluq::Handler
  extend self

  # @return [Hash] registered handlers
  def registry
    @registry ||= {}
  end

end

%w'base buffered forward'.each do |name|
  require "fluq/handler/#{name}"
end