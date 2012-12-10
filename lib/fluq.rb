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
    attr_reader :env, :root, :timers, :scheduler

    # Returns Celluloid's logger. Please use `Celluloid.logger = ...` to override.
    # @return [Logger] the thread-safe logger instance
    def logger
      Celluloid.logger
    end

    def init!
      # Detect environment
      @env  = ENV['FLUQ_ENV'] || "development"

      # Set root path
      @root = Pathname.new(ENV['FLUQ_ROOT'] || ".")

      # Initialize timers
      @timers = Timers.new

      # Start background thread to fire timers
      @scheduler = Thread.new { loop { timers.empty? ? sleep(10) : timers.wait } }
    end
    protected :init!

  end

  init!
end

%w'version error mixins url event reactor handler buffer input dsl'.each do |name|
  require "fluq/#{name}"
end
