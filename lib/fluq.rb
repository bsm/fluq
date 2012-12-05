require 'pathname'
require 'uri'
require 'fileutils'
require 'securerandom'
require 'forwardable'
require 'celluloid'
require 'atomic'

module Fluq
  extend self

  # @return [Logger] the logger instance
  def logger
    @logger || send(:logger=, begin
      path    = root.join("log", "#{env}.log")
      FileUtils.mkdir_p(path.dirname)

      default = ::Logger.new(path)
      default.level = ::Logger::INFO if env == "production"
      default
    end)
  end

  # @param [Logger] the logger to use
  def logger=(value)
    Celluloid.logger = @logger = value
  end

  # @param [String] the environment
  def env
    @env ||= ENV['FLUQ_ENV'] || "developemnt"
  end

  # @param [Pathname] the root
  def root
    @root ||= Pathname.new(ENV['FLUQ_ROOT'] || ".")
  end

  # @param [String] url the URL
  def parse_url(url)
    url = URI.parse(url)
    case url.scheme
    when "tcp", "unix"
      url
    else
      raise URI::InvalidURIError, "Invalid URI scheme, only 'tcp' and 'unix' sockets are allowed"
    end
  end

end

%w'error event server handler buffer'.each do |name|
  require "fluq/#{name}"
end