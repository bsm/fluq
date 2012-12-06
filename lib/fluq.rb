require 'pathname'
require 'uri'
require 'fileutils'
require 'securerandom'
require 'forwardable'
require 'celluloid'
require 'atomic'
require 'msgpack'

module Fluq
  extend self

  @@init = @@logger = @@env = @@root = @@reactor = nil

  def init!
    @@init ||= begin
      logger # Init the logger
    end
  end

  # @return [Logger] the logger instance
  def logger
    @@logger || send(:logger=, _default_logger)
  end

  # @param [Logger] the logger to use
  def logger=(value)
    Celluloid.logger = @@logger = value
  end

  # @param [String] the environment
  def env
    @@env ||= ENV['FLUQ_ENV'] || "developemnt"
  end

  # @param [Pathname] the root
  def root
    @@root ||= Pathname.new(ENV['FLUQ_ROOT'] || ".")
  end

  # @return [Fluq::Reactor] the reactor instance
  def reactor
    @@reactor ||= Fluq::Reactor.new
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

  private

    def _default_logger
      path = root.join("log", "#{env}.log")
      FileUtils.mkdir_p(path.dirname)

      default = ::Logger.new(path)
      default.level = ::Logger::INFO if env == "production"
      default
    end

  init!
end

%w'error event reactor handler buffer input dsl'.each do |name|
  require "fluq/#{name}"
end
