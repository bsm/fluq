require "optparse"
require "fileutils"

module FluQ
  class CLI

    # attr_reader [Hash] options
    attr_reader :options

    # Runs the CLI
    def self.run
      new.run
    end

    # Constructor
    def initialize
      super
      @options = {}
      parser.parse!(ARGV)
    end

    def run
      unless configured?
        puts parser
        exit
      end

      if options[:env]
        ENV["FLUQ_ENV"] = options[:env]
      end

      require 'fluq'

      if options[:log]
        FileUtils.mkdir_p(File.dirname(options[:log]))
        FluQ.logger = ::Logger.new(options[:log])
      end

      if options[:verbose]
        FluQ.logger.level = ::Logger::DEBUG
      end

      $LOAD_PATH.unshift FluQ.root.join('lib')

      FluQ.logger.info "Starting FluQ #{FluQ::VERSION}"
      FluQ::DSL.new(FluQ::Reactor.new, options[:config]).run

      @pidfile = options[:pidfile] || FluQ.root.join("tmp", "pids", "fluq.pid")
      FileUtils.mkdir_p(File.dirname(@pidfile))
      File.open(@pidfile, "w") {|f| f.write Process.pid }

      Signal.trap("INT", &method(:quit))
      Signal.trap("TERM", &method(:quit))
      Signal.trap("QUIT", &method(:quit))

      sleep
    end

    # @return [Boolean] true if configured
    def configured?
      options[:config] && File.file?(options[:config])
    end

    # Callback, called on exit
    def quit(*)
      FluQ.logger.info "Shutting down FluQ" if defined?(FluQ)
      FileUtils.rm_f(@pidfile) if @pidfile
      exit
    end

    protected

      def parser
        @parser ||= OptionParser.new do |o|
          o.banner = "Usage: #{File.basename($0)} [OPTIONS]"

          o.separator ""
          o.separator "Required:"

          o.on "-C", "--config FILE", "Use this config file" do |val|
            @options[:config] = val
          end

          o.separator ""
          o.separator "Optional:"

          o.on("-e", "--environment ENV", "Runtime environment (default: development)") do |val|
            @options[:env] = val
          end

          o.on("-l", "--log FILE", "File to log to (default: STDOUT)") do |val|
            @options[:log] = val
          end

          o.on("-v", "--verbose", "Use verbose output") do |val|
            @options[:verbose] = true
          end

          o.separator ""

          o.on "--pidfile FILE", "Path to pidfile (default: tmp/pids/fluq.pid)" do |val|
            @options[:pidfile] = val
          end

          o.separator ""

          o.on("-h", "--help", "Show this message") do
            puts o
            exit
          end

          o.on("-V", "--version", "Show version") do
            puts FluQ::VERSION
            exit
          end
        end
      end

  end
end
