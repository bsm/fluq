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
    # @attr_reader [Timers] global timers
    attr_reader :env, :root, :timers

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
      Thread.new { loop { timers.fire; sleep(1) } }
    end
    protected :init!

  end

  init!
end

%w'version error mixins url event reactor handler buffer input dsl'.each do |name|
  require "fluq/#{name}"
end
