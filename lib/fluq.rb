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
    # @attr_reader [Timers] timers global timers
    # @attr_reader [Thread] scheduler background scheduler
    # @attr_reader [Logger] logger the main logger
    attr_reader :env, :root, :timers, :scheduler, :logger

    # @param [Logger] instance the thread-safe logger instance
    def logger=(instance)
      @logger = Celluloid.logger = instance
    end

    def init!
      # Detect environment
      @env  = ENV['FLUQ_ENV'] || "development"

      # Set root path
      @root = Pathname.new(ENV['FLUQ_ROOT'] || ".")

      # Initialize timers
      @timers = Timers.new

      # Setup logger
      self.logger  = ::Logger.new(STDOUT)
      logger.level = ::Logger::INFO if env == "production"

      # Start background thread to fire timers
      @scheduler = Thread.new do
        loop do
          sleep 1
          begin
            timers.fire
          rescue => e
            logger.warn { "Timer task failed: #{e}" }
          end
        end
      end
    end
    protected :init!

  end

  init!
end

%w'version error mixins url event reactor handler buffer input dsl'.each do |name|
  require "fluq/#{name}"
end
