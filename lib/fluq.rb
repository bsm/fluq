require 'pathname'
require 'uri'
require 'fileutils'
require 'securerandom'
require 'forwardable'
require 'logger'
require 'eventmachine'
require 'msgpack'
require 'oj'
require 'timed_lru'

module FluQ
  %w'version error mixins'.each do |name|
    require "fluq/#{name}"
  end

  class << self

    # @attr_reader [String] env runtime environemnt
    # @attr_reader [Pathname] root project root
    # @attr_reader [Logger] logger the main logger
    attr_reader :env, :root, :logger

    # @param [Logger] instance the thread-safe logger instance
    def logger=(instance)
      instance.extend(FluQ::Mixins::Logger)
      @logger = instance
    end

    def init!
      # Detect environment
      @env  = ENV['FLUQ_ENV'] || "development"

      # Set root path
      @root = Pathname.new(ENV['FLUQ_ROOT'] || ".")

      # Setup logger
      self.logger  = ::Logger.new(STDOUT)
      logger.level = ::Logger::INFO if env == "production"
    end
    protected :init!

  end

  init!
end

%w'url event reactor handler input buffer feed dsl'.each do |name|
  require "fluq/#{name}"
end
