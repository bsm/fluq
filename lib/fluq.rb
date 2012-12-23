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
  class << self

    # @attr_reader [String] env runtime environemnt
    # @attr_reader [Pathname] root project root
    # @attr_reader [Logger] logger the main logger
    attr_reader :env, :root, :logger

    # @param [Logger] instance the thread-safe logger instance
    def logger=(instance)
      @logger = Celluloid.logger = instance
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

%w'version error mixins url event reactor handler buffer input dsl'.each do |name|
  require "fluq/#{name}"
end
