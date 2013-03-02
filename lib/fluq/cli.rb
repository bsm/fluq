require "optparse"
require "fileutils"
require "socket"

module FluQ
  class CLI
    SIGNALS = [ :QUIT, :INT, :TERM, :HUP ]

    # attr_reader [Hash] options
    attr_reader :options

    # Runs the CLI
    def self.run
      if BasicSocket.respond_to?(:do_not_reverse_lookup=)
        BasicSocket.do_not_reverse_lookup = true
      end
      new.run
    end

    # Constructor
    def initialize
      super

      # Parse options
      @options = {}
      parser.parse!(ARGV)
    end

    def run
      # Exit if not configured correctly
      unless configured?
        puts parser
        exit
      end

      # Set the environment
      if options[:env]
        ENV["FLUQ_ENV"] = options[:env]
      end

      # Boot and add project's lib/ dir to load path
      require 'fluq'
      $LOAD_PATH.unshift FluQ.root.join('lib')
      procline "(starting)"

      # Setup logger
      if options[:log]
        FileUtils.mkdir_p(File.dirname(options[:log]))
        FluQ.logger = ::Logger.new(options[:log])
      end
      if options[:verbose]
        FluQ.logger.level = ::Logger::DEBUG
      end

      # Write PID file
      @pidfile = options[:pidfile] || FluQ.root.join("tmp", "pids", "fluq.pid")
      FileUtils.mkdir_p(File.dirname(@pidfile))
      File.open(@pidfile, "w") {|f| f.write Process.pid }

      # Trap signals
      SIGNALS.each do |signal|
        trap(signal) {|*| shutdown! }
      end

      # Start
      log "Starting FluQ #{FluQ::VERSION}"
      FluQ::Reactor.run do |reactor|
        FluQ::DSL.new(reactor, options[:config]).run
        procline
      end
    end

    # @return [Boolean] true if configured
    def configured?
      options[:config] && File.file?(options[:config])
    end

    private

      # Shut down
      def shutdown!
        FluQ.logger.info "Shutting down FluQ" if defined?(FluQ)
        FileUtils.rm_f(@pidfile) if @pidfile
        exit
      end

      def log(message)
        FluQ.logger.info(message)
      end

      def procline(message = nil)
        $0 = ["fluq-rb", FluQ::VERSION, message].compact.join(" ")
      end

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
