require 'pathname'
require 'uri'
require 'fileutils'
require 'stringio'
require 'thread'
require 'securerandom'
require 'forwardable'
require 'logger'
require 'timed_lru'
require 'celluloid/io'
require 'celluloid/autostart'
require 'multi_json'

begin
  require 'msgpack'
rescue LoadError
end

module FluQ
  %w'version error mixins'.each do |name|
    require "fluq/#{name}"
  end

  class << self

    # @attr_reader [String] env runtime environemnt
    # @attr_reader [Pathname] root project root
    attr_reader :env, :root

    # @param [Logger] logger
    def logger=(logger)
      Celluloid.logger = logger
    end

    # @return [Logger]  the thread-safe logger instance
    def logger
      Celluloid.logger
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

%w'url event runner feed worker handler input format dsl'.each do |name|
  require "fluq/#{name}"
end
