require 'pathname'
require 'uri'
require 'fileutils'
require 'securerandom'
require 'forwardable'
require 'celluloid'
require 'atomic'
require 'msgpack'
require 'multi_json'

module FluQ
  extend self

  @@init = @@logger = @@env = @@root = @@reactor = nil

  def init!
    @@init ||= begin
      logger # Init the logger
    end
  end

  # @return [Logger] the logger instance
  def logger
    @@logger || log_to(STDOUT)
  end

  # @param [Logger] the logger to use
  def logger=(value)
    Celluloid.logger = @@logger = value
  end

  # @param [String] the environment
  def env
    @@env ||= ENV['FLUQ_ENV'] || "development"
  end

  # @param [Pathname] the root
  def root
    @@root ||= Pathname.new(ENV['FLUQ_ROOT'] || ".")
  end

  # @return [FluQ::Reactor] the reactor instance
  def reactor
    @@reactor ||= FluQ::Reactor.new
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

  # @param [String] path
  def log_to(path)
    path = Pathname.new(path) if path.is_a?(String)
    FileUtils.mkdir_p(path.dirname) if path.is_a?(Pathname)

    self.logger = ::Logger.new(path)
    logger.level = ::Logger::INFO if env == "production"
    logger
  end

  init!
end

%w'version error mixins event reactor handler buffer input dsl'.each do |name|
  require "fluq/#{name}"
end
